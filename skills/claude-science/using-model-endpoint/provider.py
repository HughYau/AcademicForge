"""InferProvider — the shim behind every inference-provider kernel.

An inference provider is a registered model-server endpoint (a localhost
port or a hosted URL). The kernel exists only to give the agent a Python
REPL whose network egress is scoped to that one endpoint; cells call the
server's native HTTP API directly (httpx ships in the helper env). There is
no provider SDK to import and no job lifecycle — submit/harvest stay with
the ssh and byoc families — so the helper-mode ops below all refuse.
"""
from __future__ import annotations

import os
import re
from typing import Any, Callable, Iterable, NoReturn

from operon_compute_provider import ByocError, ExecResult


class InferProvider:
    # The prologue strips any ambient INFER_*/NVIDIA_* vars before auth: the
    # only way an API key may enter this process is the host's fd-3 auth
    # handshake.
    secret_env_prefixes = ("INFER_", "NVIDIA_")
    # NGC personal keys look like "nvapi-…" — scrub naive prints.
    token_scrub_regex = re.compile(r"\bnvapi-[A-Za-z0-9_\-]{8,}")

    def __init__(self, *, repl: bool = False):
        self._repl = repl

    # ── auth + import ─────────────────────────────────────────────────────

    # env_name (the alias the key is additionally exported under) must be a
    # name that is safe to SET in this process. Mirrors SYSTEM_VARS
    # (userSecrets.ts) + INJECTION_ENV_VARS (kernels/secrets.ts) +
    # INFER_ALIAS_UNSAFE_NAMES (inferRegistry.ts); keep in sync — pinned by
    # inferProviderApplyAuth.test.ts.
    _alias_name_re = re.compile(r"(?!LD_|DYLD_)[A-Z][A-Z0-9_]{0,127}")
    _alias_denylist = frozenset((
        # SYSTEM_VARS mirror:
        "PATH", "HOME", "USER", "SHELL", "TMPDIR", "LANG", "LC_ALL", "PWD",
        "OLDPWD", "TERM", "HOSTNAME", "DISPLAY", "SSH_AUTH_SOCK",
        "PYTHONPATH", "NODE_PATH", "CONDA_PREFIX", "VIRTUAL_ENV", "BASH_ENV",
        "ENV", "PROMPT_COMMAND", "IFS", "PYTHONSTARTUP", "NODE_OPTIONS",
        "GIT_SSH_COMMAND", "GIT_ASKPASS",
        # INJECTION_ENV_VARS mirror (names not already above; LD_*/DYLD_*
        # ride the regex):
        "PYTHONHOME", "SHELLOPTS", "PS4", "ZDOTDIR",
        # INFER_ALIAS_UNSAFE_NAMES mirror (TLS trust roots + proxy routing):
        "SSL_CERT_FILE", "SSL_CERT_DIR", "REQUESTS_CA_BUNDLE",
        "CURL_CA_BUNDLE", "NODE_EXTRA_CA_CERTS",
        "NODE_TLS_REJECT_UNAUTHORIZED",
        "AWS_CA_BUNDLE", "GIT_SSL_CAINFO", "GIT_SSL_NO_VERIFY",
        "HTTP_PROXY", "HTTPS_PROXY", "NO_PROXY", "ALL_PROXY",
    ))

    def apply_auth(self, creds: dict[str, str]) -> None:
        # Hosted endpoints hand over {api_key} (resolved from the
        # registration's credential); local endpoints send nothing. Re-export
        # as INFER_API_KEY — the canonical, provider-agnostic name — so cells
        # can build their own Authorization header.
        key = creds.get("api_key", "")
        if not key:
            return
        os.environ["INFER_API_KEY"] = key
        # Also export under the registration's own credential name (env_name)
        # so cells can read the variable the user saved the key as, e.g.
        # $MY_NIM_KEY. Assignment replaces any ambient value under that name.
        # read_auth passes JSON values through untyped — a non-string
        # env_name skips the alias (matching the string-malformed behavior)
        # rather than raising out of the handshake.
        alias = creds.get("env_name", "")
        if (isinstance(alias, str) and self._alias_name_re.fullmatch(alias)
                and alias not in self._alias_denylist):
            os.environ[alias] = key

    def import_and_patch(self) -> None:
        # Nothing to import or patch — cells import httpx themselves and the
        # sandbox proxy env (HTTPS_PROXY/…) already routes them through the
        # endpoint-scoped filter.
        return None

    def install_unauth_hook(self, on_expired: Callable[[], NoReturn]) -> None:
        # No SDK to hook; a 401 from the endpoint surfaces in the cell output.
        return None

    # ── helper-mode ops (no job lifecycle for inference providers) ──────────

    def _unsupported(self) -> NoReturn:
        raise ByocError(
            "invalid_request",
            "inference providers have no job lifecycle — call the endpoint "
            "directly from the inference kernel instead of submitting a job.",
        )

    def create_sandbox(self, spec: dict[str, Any], install_id: str,
                       tags: dict[str, str] | None = None) -> str:
        self._unsupported()

    def exec(
        self,
        sandbox_id: str,
        argv: list[str],
        *,
        stdin: Iterable[bytes] | None = None,
        env: dict[str, str] | None = None,
        timeout: int | None = None,
    ) -> ExecResult:
        self._unsupported()

    def list_owned(self, install_id: str) -> list[dict[str, Any]]:
        self._unsupported()

    def read_owner(self, sandbox_id: str) -> str | None:
        self._unsupported()

    def terminate(self, sandbox_id: str) -> None:
        self._unsupported()


PROVIDER = InferProvider
