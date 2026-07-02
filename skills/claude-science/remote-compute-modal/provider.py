"""ModalProvider — the Modal-specific shim. The only file that imports `modal`.

This process runs network-isolated; the host arranges a SOCKS5 proxy on
loopback and an env var telling us where. import_and_patch() runs after
the credential is in hand and does three things in order:
  1. detour grpclib through that SOCKS5 proxy (it has no native proxy
     support) so the Modal control plane and per-task workers all reach
     the host's domain filter
  2. force aiohttp trust_env=True so blob uploads honour HTTPS_PROXY
  3. in repl mode only, wrap Sandbox.create (reject gpu=, clamp timeout,
     sanitize owner-key tags — the preload's exact self-stamp passes,
     plants are dropped) and Sandbox.set_tags (sanitize, and re-merge the
     sandbox's current owner keys: the real SDK replaces the whole tag
     list) — a redirect to the job surface, not a hard boundary."""
from __future__ import annotations

import math
import os
import re
from typing import Any, Callable, Iterable, NoReturn

from operon_compute_provider import WORK, ByocError, ExecResult

# Ownership tag (the tenancy boundary every op checks). Renamed twice — first
# in the claude-bioscience rebrand (operon_owner →
# claude-bioscience-install-id), then in the bioscience→science rename. Both
# legacy keys are still READ (read_owner / list_owned) so pre-rename sandboxes
# stay owned-and-reapable, but never written — create_sandbox stamps only the
# new key.
OWNER_TAG = "claude-science-install-id"
LEGACY_OWNER_TAGS = ("claude-bioscience-install-id", "operon_owner")
# App pre-rebrand installs created sandboxes under. Read-only: list_owned
# scans it so pre-rebrand sandboxes stay reapable. Never used on a create
# path — the unconfigured fallback is FALLBACK_APP_NAME.
LEGACY_APP_NAME = "operon-modal"
# Create-side fallback when the host doesn't supply app_name (mid-upgrade
# boot, before DB seeding). Mirrors core/src/tools/compute/appName.ts
# FALLBACK_MODAL_APP_NAME.
FALLBACK_APP_NAME = "claude-science-default"
KERNEL_TIMEOUT_CAP_S = 1800


def _sanitize_repl_tags(tags: Any) -> Any:
    """Owner-key policy for repl-supplied tag dicts. All legacy spellings are
    always dropped (never legitimately written anymore). The new spelling is
    kept ONLY when its value equals the host-exported install id — that is
    the kernel preload's own _OP_TAGS self-stamp on build_env hydrate
    sandboxes, which MUST survive so a crashed hydrate stays listable and
    reapable. Any other value is a plant and is dropped: a cell can only
    "self-stamp" exactly what the host would stamp anyway."""
    if not isinstance(tags, dict):
        return tags
    self_id = os.environ.get("OPERON_BYOC_INSTALL_ID", "")
    out = {}
    for k, v in tags.items():
        if k in LEGACY_OWNER_TAGS:
            continue
        if k == OWNER_TAG and (not self_id or v != self_id):
            continue
        out[k] = v
    return out
# PID-1 inactivity watchdog: the sandbox self-terminates after this much
# wall-clock with no job activity, so a dead daemon (or a terminate that
# never landed) leaks at most ~30 min of idle billing instead of the full
# Modal-side wall (CONTAINER timeout + harvest_margin_s (600) + 300 s
# teardown grace — see create_sandbox; the per-job timeout_seconds guard
# no longer sizes the wall), which stays as the hard backstop. At the 12 h
# container default that backstop is 12h+900s. 30 min is also the post-job
# harvest grace: the poller normally harvests within seconds of `.phase`
# appearing, so only a daemon that is down for >30 min loses outputs to
# the self-exit — the right trade against an idle GPU billing for hours.
IDLE_EXIT_S = 30 * 60
WATCHDOG_POLL_S = 30


def _watchdog_cmd(work: str = WORK, idle_exit_s: float = IDLE_EXIT_S,
                  poll_s: float = WATCHDOG_POLL_S,
                  mark: str = "/tmp/.operon_watchdog.mark") -> str:
    """Bash loop run as the sandbox's PID 1 (replaces the old bare `sleep`).

    Polled every ``poll_s``; ANY of these resets the idle clock:
      - ``run.sh`` present and ``.phase`` absent — the canonical "job
        running" signal (wrapper.sh writes ``.phase`` last, after
        out.tar.gz); a running job NEVER triggers self-exit;
      - ``{work}`` directory mtime newer than the per-poll marker — covers
        the warm-reuse ``rm -rf /work && mkdir && tar`` window where
        ``run.sh`` briefly doesn't exist, and any file create/delete in the
        workdir;
      - ``stdout.log``/``stderr.log`` mtime newer than the marker — covers a
        job whose cleanup deleted ``run.sh`` (e.g. ``rm -rf ./*`` in /work)
        but is still producing output.
    Otherwise (fresh sandbox before first submit, post-job once ``.phase``
    exists, or a silent gap) idle accumulates; exceeding ``idle_exit_s``
    exits PID 1, which terminates the container. Residual edge, accepted: a
    job that deletes its own run.sh AND writes no output for the full idle
    window is killed — indistinguishable from an abandoned sandbox from
    PID 1's viewpoint. ``[ -nt ]`` is a bash builtin, so the loop spawns no
    processes besides ``sleep``. The marker lives OUTSIDE ``{work}`` so the
    submit-time wipe can't erase it.

    Self-exit surfaces to the poller exactly like a Modal-side preemption:
    exec → NOT_FOUND → 'orphaned' (or the row is already terminal
    post-harvest). Parameterized only so the selftest can run it with
    short constants against a temp dir; production always uses the
    defaults. The loop counts *polls* (integer) rather than summing
    ``poll_s`` in shell arithmetic, so ``poll_s`` may be fractional
    (selftest sub-second scale); at the production constants the exit
    happens after the same 60 idle polls = 1800 s as before."""
    # Consecutive idle polls that add up to idle_exit_s (ceil: never exit
    # earlier than the requested idle window).
    idle_polls = max(1, math.ceil(idle_exit_s / poll_s))
    return (
        f": > {mark}; idle=0; "
        f"while [ $idle -lt {idle_polls} ]; do "
        f"sleep {poll_s}; "
        f"if {{ [ -e {work}/run.sh ] && [ ! -e {work}/.phase ]; }} "
        f"|| [ {work} -nt {mark} ] "
        f"|| [ {work}/stdout.log -nt {mark} ] "
        f"|| [ {work}/stderr.log -nt {mark} ]; "
        f"then idle=0; else idle=$((idle+1)); fi; "
        f": > {mark}; "
        "done"
    )


class ModalProvider:
    secret_env_prefixes = ("MODAL_", "AWS_")
    token_scrub_regex = re.compile(r"\b(?:ak|as)-[A-Za-z0-9]{4,}")

    def __init__(self, *, repl: bool = False):
        self._repl = repl
        self._modal: Any = None
        self._app: Any = None
        self._app_name: str = FALLBACK_APP_NAME
        self._prior_app_names: list[str] = []
        # Modal Environment (compute_providers.modal_environment, rides
        # req.json beside app_name). None == not configured == every
        # environment-scoped SDK call OMITS the kwarg, so Modal resolves
        # its own default (MODAL_ENVIRONMENT > ~/.modal.toml profile >
        # the workspace default env). Never defaulted to "main" here.
        self._environment: str | None = None

    # ── auth + import ────────────────────────────────────────────────────────

    def apply_auth(self, creds: dict[str, str]) -> None:
        os.environ["MODAL_TOKEN_ID"] = creds["token_id"]
        os.environ["MODAL_TOKEN_SECRET"] = creds["token_secret"]

    def set_app_name(self, name: Any) -> None:
        """Configured Modal app for Claude Science sandboxes (compute_providers.
        app_name, rides every op's req.json). Called by run_oneshot AFTER
        import_and_patch — which is why the App.lookup is lazy (_get_app),
        not eager here. Falsy/non-str → keep FALLBACK_APP_NAME."""
        if isinstance(name, str) and name:
            self._app_name = name

    def set_environment(self, name: Any) -> None:
        """Configured Modal Environment (compute_providers.modal_environment,
        rides every op's req.json beside app_name). Falsy/non-str → stay
        unset, which means NO environment kwarg on any SDK call — never a
        literal "main"."""
        if isinstance(name, str) and name:
            self._environment = name

    def _env_kw(self) -> dict[str, Any]:
        """The `environment_name=` kwarg for every Modal call that resolves
        an object BY NAME (App.lookup, Volume.from_name). Empty dict when
        unset so the unset call is BYTE-IDENTICAL to a build that predates
        the setting. Sandbox.create deliberately does NOT take this: its
        `environment_name=` kwarg is deprecated in modal 1.5.x — a sandbox
        lives in its app's environment, and our `app=` always comes from
        the env-scoped `_get_app()`. Sandbox.from_id / Image.from_id take
        global ids and have no environment parameter at all."""
        return (
            {"environment_name": self._environment} if self._environment else {}
        )

    def set_prior_app_names(self, names: Any) -> None:
        """Apps this install was previously configured with
        (compute_providers.prior_app_names, rides req.json beside
        app_name). list_owned scans them so sandboxes created before a
        rename stay listable for the reaper and the Disable sweep."""
        if isinstance(names, list):
            self._prior_app_names = [
                n for n in names if isinstance(n, str) and n
            ]

    def import_and_patch(self) -> None:
        # The repl bootstrap exports the configured Modal Environment, but the
        # helper prologue scrubs every `MODAL_*` var it inherited (the user's
        # shell may carry stray Modal/AWS config or credentials) — so the
        # SDK's own channel never survives to this point. The host also
        # exports the same value as OPERON_BYOC_ENVIRONMENT, which the scrub
        # leaves alone: re-publish it under the SDK's name now (post-scrub,
        # pre-import) and record it for `_env_kw()`, so every name this
        # process resolves — the kernel preload's App.lookup, build_env(),
        # an env file's own Volume.from_name — lands in the configured
        # Environment. Absent the var (oneshot path, or no Environment
        # configured) nothing is invented.
        _env_cfg = os.environ.get("OPERON_BYOC_ENVIRONMENT")
        if _env_cfg:
            os.environ.setdefault("MODAL_ENVIRONMENT", _env_cfg)
            self.set_environment(_env_cfg)
        if os.environ.get("OPERON_MOCK_MODAL", "").lower() in {"1", "true", "yes", "on"}:
            # CI / dev mode: swap the real SDK for the in-process fake. The
            # fake lives next to operon_compute_provider on disk (same
            # assets/compute dir), so it's already on sys.path when the
            # helper runs. Skipping the aiohttp/grpclib patches is the
            # point — neither is installed on a CI runner, and the mock
            # never opens a socket.
            import sys  # noqa: PLC0415
            import mock_modal as modal  # noqa: PLC0415
            sys.modules.setdefault("modal", modal)
            self._modal = modal
            if self._repl:
                self._install_gpu_guard(modal)
            return
        self._patch_aiohttp_trust_env()
        self._patch_grpclib_socks()
        import modal  # noqa: PLC0415

        self._modal = modal
        if self._repl:
            self._install_gpu_guard(modal)

    def _get_app(self) -> Any:
        """App.lookup deferred to first use so set_app_name (req.json, read
        after import_and_patch) can take effect before any control-plane
        round-trip."""
        if self._app is None:
            self._app = self._modal.App.lookup(
                self._app_name, create_if_missing=True, **self._env_kw())
        return self._app

    def install_unauth_hook(self, on_expired: Callable[[], NoReturn]) -> None:
        try:
            import grpclib.exceptions  # noqa: PLC0415

            orig = grpclib.exceptions.GRPCError.__init__

            def hook(self_, status, *a, **kw):
                orig(self_, status, *a, **kw)
                if getattr(status, "name", "") == "UNAUTHENTICATED":
                    on_expired()

            grpclib.exceptions.GRPCError.__init__ = hook  # type: ignore[method-assign]
        except Exception:
            pass

    # ── helper-mode ops ──────────────────────────────────────────────────────

    def create_sandbox(self, spec: dict[str, Any], install_id: str,
                       tags: dict[str, str] | None = None) -> str:
        m = self._modal
        sb = None
        try:
            kw: dict[str, Any] = {
                "image": self._resolve_image(spec["image"]),
                # Modal's wall = container timeout + harvest margin + 300 s
                # slack. The wrapper's watchdog fires first (wall − margin)
                # and stages outputs; this wall is the never-user-facing
                # backstop. The margin is threaded from the host
                # (BYOC_HARVEST_MARGIN_SEC rides the create spec) so wall
                # and watchdog share one number; 600 is only the fallback
                # for an old host that doesn't send it.
                "timeout": int(spec["timeout"])
                + int(spec.get("harvest_margin_s") or 600)
                + 300,
                "app": self._get_app(),
                # Tags ride the create call (modal>=1.4.3 supports tags=) so
                # there is no crash window where a billable sandbox exists
                # untagged — the old post-create set_tags left exactly that
                # gap. Owner is merged LAST and ALL legacy owner keys are
                # stripped from the incoming tags: a host-supplied entry can
                # never override (or smuggle in via a legacy spelling) the
                # ownership scope list_owned/read_owner key on.
                "tags": {
                    **{k: v for k, v in (tags or {}).items()
                       if k not in LEGACY_OWNER_TAGS},
                    OWNER_TAG: install_id,
                },
            }
            for k in ("gpu", "cpu", "memory"):
                if spec.get(k) is not None:
                    kw[k] = spec[k]
            if spec.get("volumes"):
                kw["volumes"] = {p: m.Volume.from_name(n, create_if_missing=True,
                                                       **self._env_kw())
                                 for p, n in spec["volumes"].items()}
            # Outbound-domain allowlist, HOST-STAMPED beside harvest_margin_s
            # from compute_providers.egress_policy (a column the agent has no
            # edit path to). It is deliberately NOT a provider_params field —
            # ModalParamsSchema is .strict() and rejects it — so the agent
            # can never set or widen its own fence. Three states, kept
            # exactly distinct:
            #   absent / None  -> NEITHER kwarg is set: the create call is
            #                     byte-identical to a build that predates the
            #                     feature (every NULL/legacy row, explicit
            #                     unrestricted, and mirror-with-isolation-off).
            #   non-empty      -> outbound_domain_allowlist=[...]. Modal's
            #                     allowlist is Beta and TLS/443-only; the
            #                     SKILL.md egress section documents what that
            #                     does and doesn't cover.
            #   []             -> block_network=True. An EMPTY allowlist is a
            #                     real answer ("nothing survived the merge"),
            #                     never silently widened to "no allowlist".
            oda = spec.get("egress_allowlist")
            if oda is not None:
                if oda:
                    kw["outbound_domain_allowlist"] = [str(d) for d in oda]
                else:
                    kw["block_network"] = True
            # Explicit keepalive: jobs run as a detached background process
            # inside the sandbox; without a long-lived PID 1, Modal would
            # reap the container before the job finishes or its output can
            # be collected. The keepalive is the inactivity watchdog (see
            # _watchdog_cmd) rather than a bare `sleep <timeout>`, so an
            # abandoned sandbox self-terminates after IDLE_EXIT_S instead
            # of billing out the whole container-timeout+margin+300 wall.
            sb = m.Sandbox.create("bash", "-c", _watchdog_cmd(), **kw)
        except ByocError:
            raise
        except Exception as e:  # noqa: BLE001
            if sb is not None:
                try:
                    sb.terminate()
                except Exception:
                    pass
            raise self._map_err(e) from None
        return sb.object_id

    def exec(self, sandbox_id: str, argv: list[str], *, stdin: Iterable[bytes] | None = None,
             env: dict[str, str] | None = None, timeout: int | None = None) -> ExecResult:
        sb = self._modal.Sandbox.from_id(sandbox_id)
        kw: dict[str, Any] = {"text": False}
        if env:
            kw["env"] = env
        if timeout:
            kw["timeout"] = timeout
        try:
            p = sb.exec(*argv, **kw)
        except Exception as e:  # noqa: BLE001
            raise self._map_err(e) from None
        if stdin is not None:
            for chunk in stdin:
                p.stdin.write(chunk)
                p.stdin.drain()
            p.stdin.write_eof()
            p.stdin.drain()
        return _ExecAdapter(p)

    def _lookup_existing_app(self, name: str) -> Any | None:
        """App.lookup with create_if_missing=False, returning None only on
        not_found — every other failure (auth, rate-limit, transient
        outage) propagates so the reaper/Disable sweep see a FAILED
        reconcile instead of a silently incomplete one."""
        try:
            return self._modal.App.lookup(
                name, create_if_missing=False, **self._env_kw())
        except ByocError:
            raise
        except Exception as e:  # noqa: BLE001
            # Skip ONLY on the SDK's own NotFoundError type (modal.exception
            # .NotFoundError; the mock mirrors the class name). _map_err's
            # repr-substring routing stays display-only here — a transient/
            # internal error whose MESSAGE merely mentions "NotFound" must
            # fail the reconcile, not silently shrink it.
            if type(e).__name__ == "NotFoundError":
                return None
            raise self._map_err(e) from None

    def list_owned(self, install_id: str) -> list[dict[str, Any]]:
        """Union of every (app, owner-key) combination a Claude Science sandbox of
        this install can exist under, deduped by object_id:
          - configured app + new key       (anything created post-rename)
          - configured app + each legacy key (created mid-rollout under the
            new app by a build that still wrote an older key)
          - the hardcoded fallback + legacy apps, each with new key + each
            legacy key (covers the NULL-app_name fallback window and
            pre-rebrand sandboxes respectively)
          - each previously-configured app + new key + each legacy key
            (sandboxes created before a Default-app rename;
            compute_providers.prior_app_names)
        An app that doesn't exist is skipped via not_found; any other
        lookup/listing failure propagates (the reaper must know the list
        failed rather than silently see zero sandboxes)."""
        m = self._modal
        try:
            combos: list[tuple[Any, str]] = [
                (self._get_app(), OWNER_TAG),
                *[(self._get_app(), k) for k in LEGACY_OWNER_TAGS],
            ]
            for extra_name in (FALLBACK_APP_NAME, LEGACY_APP_NAME):
                if extra_name == self._app_name:
                    continue
                extra = self._lookup_existing_app(extra_name)
                if extra is not None:
                    combos.append((extra, OWNER_TAG))
                    combos.extend((extra, k) for k in LEGACY_OWNER_TAGS)
            for prior_name in self._prior_app_names:
                if prior_name in (self._app_name, FALLBACK_APP_NAME, LEGACY_APP_NAME):
                    continue  # already covered above
                prior = self._lookup_existing_app(prior_name)
                if prior is not None:
                    combos.append((prior, OWNER_TAG))
                    combos.extend((prior, k) for k in LEGACY_OWNER_TAGS)
            out: list[dict[str, Any]] = []
            seen: set[str] = set()
            for app, key in combos:
                for sb in m.Sandbox.list(
                        app_id=app.app_id, tags={key: install_id}):
                    if sb.object_id in seen:
                        continue
                    seen.add(sb.object_id)
                    out.append(
                        {"sandbox_id": sb.object_id, "tags": sb.get_tags()})
            return out
        except ByocError:
            raise
        except Exception as e:  # noqa: BLE001
            raise self._map_err(e) from None

    def read_owner(self, sandbox_id: str) -> str | None:
        try:
            tags = self._modal.Sandbox.from_id(sandbox_id).get_tags()
            # Dual-read: pre-rename sandboxes carry only a legacy key.
            return tags.get(OWNER_TAG) or next(
                (tags[k] for k in LEGACY_OWNER_TAGS if k in tags), None)
        except Exception as e:  # noqa: BLE001
            raise self._map_err(e) from None

    def terminate(self, sandbox_id: str) -> None:
        try:
            self._modal.Sandbox.from_id(sandbox_id).terminate()
        except Exception as e:  # noqa: BLE001
            raise self._map_err(e) from None

    def list_dir(self, root: str, path: str = "/", *, limit: int | None = None) -> list[dict[str, Any]]:
        """List a Modal Volume. ``root`` is the volume name (not a mount path)."""
        m = self._modal
        try:
            vol = m.Volume.from_name(root, create_if_missing=False,
                                     **self._env_kw())
            entries = []
            # Real Modal's Volume.iterdir defaults to recursive=True; the
            # file browser wants immediate children only.
            for e in vol.iterdir(path or "/", recursive=False):
                entries.append({
                    "name": e.path.rsplit("/", 1)[-1],
                    "type": "dir" if e.type == m.volume.FileEntryType.DIRECTORY else "file",
                    "size": e.size or 0,
                    # RemoteDirEntry.mtime is epoch ms; Modal's FileEntry.mtime
                    # is epoch seconds.
                    "mtime": int(e.mtime * 1000) if e.mtime is not None else None,
                })
            # Sort before slicing so ``limit`` keeps a best-effort
            # alphabetically-first N (dirs before files; casefolded primary
            # key roughly mirrors the TS side's localeCompare) — Modal
            # doesn't document iterdir order. The cap still bounds what gets
            # serialized through the helper.
            entries.sort(
                key=lambda x: (x["type"] != "dir", x["name"].casefold(), x["name"])
            )
            return entries[:limit] if limit is not None else entries
        except Exception as e:  # noqa: BLE001
            raise self._map_err(e) from None

    def list_volumes(self) -> list[dict[str, Any]]:
        """List all Volumes in the workspace — the file browser's landing
        view for ``byoc:modal`` at path ``/``. ``created_at`` is epoch ms
        to match ``RemoteDirEntry.mtime``."""
        m = self._modal
        try:
            out: list[dict[str, Any]] = []
            # modal==1.4.1 enumerates volumes via the Volume.objects manager
            # namespace, not a Volume classmethod. The returned handles are
            # hydrated, so info() reads local metadata without a per-volume
            # round-trip. VolumeInfo.created_at is a datetime; convert to
            # epoch ms here to match RemoteDirEntry.mtime downstream.
            # Environment-scoped like every other BY-NAME resolution: without
            # the kwarg this landing view enumerates the DEFAULT environment
            # while list_dir/read_file resolve names in the CONFIGURED one,
            # so the browser lists volumes it then cannot open (review
            # r3477802793). Unset → kwarg omitted, byte-identical to before.
            for v in m.Volume.objects.list(**self._env_kw()):
                name = v.name
                if not name:
                    # Volume.name is Optional[str]; an anonymous handle can't
                    # be re-opened via from_name so there's nothing to browse.
                    continue
                info = v.info()
                ca = getattr(info, "created_at", None)
                out.append({
                    "name": name,
                    "created_at": (
                        int(ca.timestamp() * 1000) if ca is not None else None
                    ),
                })
            out.sort(key=lambda x: (x["name"].casefold(), x["name"]))
            return out
        except Exception as e:  # noqa: BLE001
            raise self._map_err(e) from None

    def read_file(self, root: str, path: str) -> Iterable[bytes]:
        """Stream one file from a Modal Volume for the file browser's
        Import and Download actions. ``root`` is the volume name;
        ``path`` is volume-relative (leading ``/`` stripped to match
        ``iterdir``'s convention)."""
        m = self._modal
        try:
            vol = m.Volume.from_name(root, create_if_missing=False,
                                     **self._env_kw())
            yield from vol.read_file(path.lstrip("/"))
        except ByocError:
            raise
        except Exception as e:  # noqa: BLE001
            raise self._map_err(e) from None

    # ── internals ────────────────────────────────────────────────────────────

    def _resolve_image(self, ref: str) -> Any:
        m = self._modal
        if ref.startswith("im-"):
            return m.Image.from_id(ref)
        if "/" not in ref and ":" not in ref:
            raise ByocError(
                "invalid_request",
                f"image {ref!r} is neither a Modal im-* id nor a registry "
                f"reference (host/name:tag) — build the image first and "
                f"pass the returned im-* id.",
            )
        return m.Image.from_registry(ref)

    def _patch_grpclib_socks(self) -> None:
        """grpclib has no proxy support. Detour Channel._create_connection
        through SOCKS5 so both the control plane (api.modal.com) and
        per-task workers (*.w.modal.host) resolve and connect via the
        byoc DomainFilter. grpclib does its own TLS+ALPN over the SOCKS
        tunnel, so the helper sees a real end-to-end TLS session — no
        host-side termination needed.

        On Linux this process runs in its own network namespace; the only
        egress is a SOCKS5 listener at a fixed loopback port that bridges
        out to the host's domain filter. On macOS there is no namespace
        isolation, so the host injects the proxy's actual port via env."""
        socks_port = self._socks_port()
        if socks_port is None:
            return  # direct-net (tests / unsandboxed)
        try:
            import asyncio  # noqa: PLC0415
            import ssl  # noqa: PLC0415

            import grpclib.client  # noqa: PLC0415
            from python_socks.async_.asyncio import Proxy  # noqa: PLC0415

            socks_url = f"socks5://127.0.0.1:{socks_port}"

            async def via_socks(self_):  # type: ignore[no-untyped-def]
                if self_._path is not None:  # unix path → unchanged
                    return await orig(self_)
                proxy = Proxy.from_url(socks_url, rdns=True)
                sock = await proxy.connect(self_._host, self_._port)
                ssl_ctx = self_._ssl
                if ssl_ctx is True:
                    ssl_ctx = ssl.create_default_context()
                _, protocol = await asyncio.get_running_loop().create_connection(
                    self_._protocol_factory,
                    sock=sock,
                    ssl=ssl_ctx,
                    server_hostname=self_._host if ssl_ctx else None,
                )
                return protocol

            orig = grpclib.client.Channel._create_connection
            grpclib.client.Channel._create_connection = via_socks  # type: ignore[method-assign]
        except Exception as e:
            # Fail-closed: without the patch grpclib would attempt a
            # direct connect and silently hang inside the isolated
            # namespace. Surface a structured error instead of a timeout.
            raise ByocError("network_bridge_down",
                            f"grpclib SOCKS patch failed: {e!r}") from None

    # Fixed port the host's bridge listens on inside the Linux network
    # namespace. macOS has no namespace; the host passes the real proxy port
    # via OPERON_BYOC_PROXY_SOCKS instead.
    _INNER_SOCKS_PORT = 1080

    @classmethod
    def _socks_port(cls) -> int | None:
        if os.environ.get("OPERON_BYOC_SOCK_DIR"):
            return cls._INNER_SOCKS_PORT
        if p := os.environ.get("OPERON_BYOC_PROXY_SOCKS"):
            return int(p)
        return None

    def _patch_aiohttp_trust_env(self) -> None:
        if self._socks_port() is None:
            return  # unconfined: aiohttp default trust_env=False is fine
        try:
            from modal._utils import http_utils  # noqa: PLC0415

            # ClientSessionRegistry.get_session() takes no args (modal ≥1.1) —
            # the earlier attempt to pass trust_env=True there hit TypeError at
            # first blob op. Target the factory it delegates to instead, and
            # flip the attr aiohttp reads per-request so modal's certifi/TLS
            # connector setup is preserved verbatim.
            orig = http_utils._http_client_with_tls

            def patched(timeout):
                sess = orig(timeout)
                sess._trust_env = True
                return sess

            http_utils._http_client_with_tls = patched
        except Exception as e:
            # Fail-closed: without trust_env, aiohttp blob I/O would
            # ignore HTTPS_PROXY and hang opaquely inside the isolated
            # namespace.
            raise ByocError(
                "network_bridge_down",
                f"aiohttp trust_env patch failed: {e!r} — blob I/O would bypass the proxy",
            ) from None

    def _install_gpu_guard(self, m: Any) -> None:
        orig = m.Sandbox.create

        def guarded(*a, **kw):
            if kw.get("gpu"):
                raise ByocError(
                    "invalid_request",
                    "GPU sandboxes go through host.compute.create('byoc:modal', ...); "
                    "that raises its own approval card.",
                )
            t = kw.get("timeout")
            if t is None or t > KERNEL_TIMEOUT_CAP_S:
                kw["timeout"] = KERNEL_TIMEOUT_CAP_S
            if kw.get("tags"):
                kw["tags"] = _sanitize_repl_tags(kw["tags"])
            # NOTE(egress): the JOB path (host.compute.create -> _op_create ->
            # create_sandbox above) stamps the provider's egress_policy as an
            # outbound_domain_allowlist. THIS path -- a repl cell calling
            # modal.Sandbox.create directly, incl. the kernel preload's
            # build_env(hydrate=True) -- is deliberately NOT fenced yet. The
            # other defaults this guard injects (the gpu reject, the timeout
            # clamp) are CONSTANTS; the egress policy is per-provider DB
            # state the host plumbs into the JOB approval flow but does NOT
            # currently export into the compute_provider kernel's environment
            # (no OPERON_BYOC_* variable carries it), and inventing a new env
            # channel here would be a guess the host never validates. Like
            # the rest of this guard it is a REDIRECT, not a boundary
            # (bypassable via raw gRPC); the billing/consent bound on this
            # path stays the byoc_kernel grant + Modal workspace quotas. The
            # gap is recorded explicitly in core/assets/compute/SECURITY.md
            # ("Accepted residuals") -- close it by exporting the merged list
            # as an env var beside OPERON_BYOC_INSTALL_ID and reading it
            # here, not by widening this kernel-side default in isolation.
            return orig(*a, **kw)

        m.Sandbox.create = staticmethod(guarded)  # type: ignore[assignment]

        # Same soft-boundary tier as the gpu/timeout clamp above: repl cells
        # can retag freely EXCEPT the two owner keys, so a kernel cell can't
        # plant a divergent-owner shape (listed via one key, disowned via
        # the other) that every reconcile returns but no terminate touches.
        # The real SDK's set_tags is REPLACE semantics (the request carries
        # the complete tag list), so the guard re-merges the sandbox's
        # CURRENT owner-key values on top of the sanitized dict — otherwise
        # any retag omitting the owner key (hostile or a benign
        # set_tags({"experiment": "r1"})) would erase the host stamp and
        # orphan the sandbox from every list_owned union. A get_tags failure
        # propagates: refusing the retag beats silently erasing ownership.
        orig_set = m.Sandbox.set_tags

        def guarded_set_tags(self_, tags, *a, **kw):
            merged = _sanitize_repl_tags(tags)
            if isinstance(merged, dict):
                merged = dict(merged)
                cur = self_.get_tags()
                # Preserve EVERY identity key, not just the owner spellings:
                # the enable-time reaper's hydrate exemption keys on the
                # frame tag, so letting a benign replace-semantics retag
                # drop it would un-protect a live hydrate from the next
                # re-enable pass. Both prefix generations are preserved —
                # pre-rename sandboxes carry claude-bioscience-* identity
                # tags and must keep them for the reaper's dual-read.
                for k, v in cur.items():
                    if (k in LEGACY_OWNER_TAGS
                            or k.startswith("claude-science-")
                            or k.startswith("claude-bioscience-")):
                        merged[k] = v
            return orig_set(self_, merged, *a, **kw)

        m.Sandbox.set_tags = guarded_set_tags  # type: ignore[assignment]

    def _map_err(self, e: Exception) -> ByocError:
        s = repr(e)
        raw = str(e).strip()
        if "UNAUTHENTICATED" in s or "Unauthorized" in s:
            return ByocError(
                "unauthorized",
                "Modal rejected the token — it was revoked or the kernel outlived its TTL. "
                "Re-open the compute_provider kernel (it re-reads ~/.modal.toml). "
                f"({raw})",
            )
        if "RESOURCE_EXHAUSTED" in s or "quota" in s.lower() or "spend limit" in s.lower():
            return ByocError(
                "quota_exhausted",
                "Modal workspace quota, concurrent-GPU limit, or spend limit reached. "
                "A concurrent limit frees up when idle handles and sandboxes are "
                "closed — they count against it. A spend limit doesn't: accrued "
                "spend stays accrued — raise it at https://modal.com/settings/plan, "
                f"or lower gpu/cpu. ({raw})",
            )
        if "SandboxCancelled" in s or "Sandbox was cancelled" in s:
            return ByocError(
                "not_found",
                "Modal reports the sandbox was cancelled (via the Modal "
                "dashboard, API, or platform). The sandbox is gone and "
                f"outputs are unrecoverable. ({raw})",
            )
        if "UNAVAILABLE" in s or "DEADLINE_EXCEEDED" in s:
            return ByocError(
                "transient",
                "Modal API was unreachable or timed out — usually transient. Retry in "
                f"~30s; if it persists check https://status.modal.com. ({raw})",
            )
        # Real Modal's NotFoundError has no custom __repr__, so the grpc
        # status token "NOT_FOUND" is only in the repr when the error came
        # straight from grpclib. Volume.from_name / .read_file raise
        # modal.exception.NotFoundError / FileNotFoundError respectively —
        # both caught by the class-name substring.
        if "NOT_FOUND" in s or "NotFound" in s:
            return ByocError(
                "not_found",
                "Modal can no longer find the referenced object. For a "
                "sandbox: it was terminated (idle-watchdog, OOM, "
                "preemption, or cancellation) — outputs inside it are "
                "unrecoverable. For an im-* image id: it was "
                "garbage-collected — rebuild and re-record the new id. "
                f"({raw})",
            )
        if "INVALID_ARGUMENT" in s or "InvalidError" in s:
            return ByocError(
                "invalid_request",
                "Modal rejected the request shape. If this names the sandbox "
                "timeout: Modal's platform caps a sandbox lifetime at 24 h — "
                "pass a container timeout of at most 85500 s (24 h minus the "
                "harvest margin and teardown grace). If it names "
                "outbound_domain_allowlist: the workspace's Modal plan does "
                "not include the (Beta) domain allowlist, or the installed "
                "modal SDK predates it — the user can set the provider's "
                "egress policy to Unrestricted in Settings → Compute → "
                f"modal as a workaround. ({raw})",
            )
        if "RateLimit" in s or "TOO_MANY" in s:
            return ByocError(
                "rate_limited",
                "Modal rate-limited this token. Back off ~60s before retrying; "
                f"stagger fan-out submissions if you're looping. ({raw})",
            )
        return ByocError(
            "transient",
            f"Unexpected Modal SDK error — retry once; if it persists report the trace. ({raw})",
        )


class _ExecAdapter:
    def __init__(self, p: Any):
        self._p = p

    @property
    def stdout(self) -> Iterable[bytes]:
        for chunk in self._p.stdout:
            yield chunk if isinstance(chunk, bytes) else chunk.encode("utf-8")

    @property
    def stderr(self) -> Iterable[bytes]:
        for chunk in getattr(self._p, "stderr", None) or ():
            yield chunk if isinstance(chunk, bytes) else chunk.encode("utf-8")

    def wait(self) -> int:
        rc = self._p.wait()
        # Defensive: Modal v1.4.x types wait() -> int, but older/future SDKs
        # may return None if the exit status couldn't be reaped. `or 0` would
        # coerce that to success — map to 137 (128+SIGKILL) instead.
        return rc if rc is not None else 137


PROVIDER = ModalProvider
