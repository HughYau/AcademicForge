---
name: managed-model-endpoints
description: Register a model service in the managed family — a local model server container the daemon starts/stops on demand, or a remote upstream model API (https). Read the runbook, allocate a port (local only), compose idempotent start/stop scripts (local only), register once. Load when the user wants a model service available for inference, or when list_compute shows managed endpoints.
license: Apache-2.0
---

# Managed model endpoints

A **managed model endpoint** is a model service the **daemon** owns: you
register it **once**, then every `compute_provider` cell against it just
works — the daemon swaps the resident model off the device (one model at a
time, via the resident's own approved stop), runs your approved start
script, waits for the readiness route, then runs your cell, streaming its
lifecycle progress into the cell as it goes. You never run the container
runtime yourself, never poll readiness in cells, and never see the
credential value. Two verbs: `register()` (asks the user once) and ordinary
inference cells.

Container specifics — image, registry login, internal port, cache mount
target, readiness route — come from the **model's own runbook skill**; this
skill is the translation contract.

## Calling a registered endpoint — inference cells

Calling a registered endpoint — use the `using-model-endpoint` skill
(this skill is the REGISTRATION contract; that one documents the call
side in full).

The ONLY dispatch form is the `compute_provider` tool with the endpoint's
registered name (`list_compute` shows them):

```
compute_provider(provider="boltz2-service", code="""
import requests
r = requests.post(BASE_URL + "/v1/infer", json=payload)
""")
```

The daemon brings the model up on demand (a first cold start downloads
image + weights — minutes; let it run) and preloads `BASE_URL` into the
cell — both as a Python variable (use it directly, as above) and as
`os.environ["BASE_URL"]` (plus `INFER_API_KEY` for remote endpoints). Endpoints are
**not kernel environments**: `environment="boltz2-service"` on a plain
python cell fails — plain cells get no `BASE_URL`.

## Enablement — once per machine

The user connects the family under **Customize → Compute → Model
endpoints** (the setup flow saves the family credential first —
connect-without-key is not a state) and picks ONE mode: **Local**
(container registrations) or **URL/remote** (https against the configured
host). Until connected, `free_port()`/`register()` raise a precise error —
relay it; in the wrong mode they refuse with a teaching error naming the
setting (existing endpoints of the unarmed leg keep dispatching — only NEW
registrations refuse). **Disconnecting is a full teardown**: every active
local service is stopped via its approved stop script and every
registration (local AND hosted) is removed; caches stay on disk; a failing
stop keeps that one row, FAILED. The "Local machine GPU" toggle never
gates registration — it governs cell GPU access only; the approval card is
the per-registration gate.

**Credential contract (platform rule):** every registration passes
`credential="NVIDIA_API_KEY"` — the daemon rejects any other name. Locally
the value feeds the start script's registry login and never enters your
kernel env; for remote endpoints it authenticates the upstream and is
delivered only into the inference cell's env (as `INFER_API_KEY`), never
the repl kernel.

## Register (repl kernel)

```python
port = host.model_endpoints.free_port()        # local only; random 20000-29999

host.model_endpoints.register(
    name="boltz2-service",            # <model>-service -- descriptive, never the
                                      # bare model name (collides/ambiguous)
    url=f"http://127.0.0.1:{port}",   # LITERAL 127.0.0.1 -- `localhost` rejected
    credential="NVIDIA_API_KEY",      # the family credential NAME, never a value
    skill="<model-runbook-skill>",
    start=START_SCRIPT,               # composed below
    stop="docker stop boltz2-service",# exit 0 ONLY once actually stopped
    live="/v1/health/ready",          # readiness ROUTE (200 = model answers;
                                      # "up but loading" must read not-ready)
)
```

Name endpoints `<model>-service` (e.g. `diffdock-service`) — unambiguous in
provider lists; never just the bare model name. Name the CONTAINER after
the endpoint too (the template above does): the UI then follows the
service's own logs live while it starts.

`register()` **always cards the user** (scripts verbatim, port, service dir,
credential name). One exception: a **byte-identical** re-registration is
silent — same bytes are approved forever; any byte change re-cards. The
registration stays inspectable under Customize → Compute. Re-registering to
fix scripts: **reuse the existing url** — never call `free_port()` again
(the port is the endpoint's stable mutex).

## Remote endpoints — upstream APIs (no lifecycle)

Pass `url="https://<upstream>"` and **omit `start`/`stop`/`live`** — no
port, no scripts, no readiness. Requires URL/remote mode (the setup
radio; in Local mode https registrations refuse). The url's HOST must
equal the configured upstream host exactly — you pick the path leaf,
never the authority. After approval,
cells are plain HTTP clients of `BASE_URL` authenticating with
`$INFER_API_KEY`. `list_compute` labels every row
`location: "local" | "remote"`.

## Composing the start script

The daemon hands scripts three things in their **process environment**
(never argv, never sudo): `HOST_PORT` (the registered port), `SERVICE_DIR`
(this endpoint's persistent directory — put the model cache here), and the
credential value under its own name. Nothing else is inherited — ambient
tokens are not visible; the ONLY secret a script sees is its registered
credential.

The start script must be **idempotent** (cold create / warm start / crash
re-entry), with the **port-mismatch guard** — the runtime freezes port
mappings at container creation, so a container created under an OLD port
must be recreated or readiness can never pass:

```bash
mkdir -p "$SERVICE_DIR/cache"
# docker login persists auth in $DOCKER_CONFIG/config.json; scope it to the
# service dir so the credential dies with the service (never ~/.docker).
export DOCKER_CONFIG="$SERVICE_DIR/.docker"
create_service() {
  docker run -d --name boltz2-service \
    --restart unless-stopped \
    -p 127.0.0.1:${HOST_PORT}:8000 --gpus all \
    -e NVIDIA_API_KEY \
    -v "$SERVICE_DIR/cache:<cache target from the runbook>" \
    <image from the runbook>
}
if docker inspect boltz2-service >/dev/null 2>&1 && \
   [ "$(docker inspect -f '{{(index (index .HostConfig.PortBindings "8000/tcp") 0).HostPort}}' boltz2-service)" != "$HOST_PORT" ]; then
  docker rm -f boltz2-service          # stale port mapping -- recreate below
fi
if docker inspect boltz2-service >/dev/null 2>&1; then
  docker start boltz2-service          # warm wake -- no credential, no chown needed
else
  echo "$NVIDIA_API_KEY" | docker login <registry> --username '<user>' --password-stdin
  docker pull <image from the runbook>
  # Cache must be writable by the CONTAINER's user, whose uid the image
  # defines (container uid != host uid). chown needs root the script doesn't
  # have; a throwaway root container does it -- and the chmod, which the
  # host user can no longer do once the dir is chowned away -- without sudo.
  CUID="$(docker inspect --format '{{.Config.User}}' <image from the runbook> 2>/dev/null | cut -d: -f1)"
  case "$CUID" in ''|root) CUID=0;; *[!0-9]*) CUID=1000;; esac   # named user -> default 1000; runbook may override
  if [ "$CUID" != "0" ]; then
    docker run --rm -v "$SERVICE_DIR/cache:/c" alpine sh -c "chown -R $CUID:$CUID /c && chmod 700 /c"
  else
    chmod 700 "$SERVICE_DIR/cache" 2>/dev/null || true
  fi
  create_service
fi
# RUNTIME-binding guard (one retry): after a port-conflict crash the engine
# can start the container yet silently skip port programming -- the CONFIG
# still matches $HOST_PORT (so the guard above cannot catch it) but
# `docker port` prints nothing and the model serves to nobody. Recreate.
if [ -z "$(docker port boltz2-service 2>/dev/null)" ]; then
  docker rm -f boltz2-service
  create_service
fi
```

Translation rules:

- **Keep scripts ASCII** — non-ASCII (em dashes, arrows, curly quotes)
  triggers the approval card's spoofing warning; use `--` and `->` in
  comments.
- **`export DOCKER_CONFIG="$SERVICE_DIR/.docker"`** before any `docker
  login` — login persists the credential in `config.json`, and scoping it
  to the service dir means Remove honestly reclaims it (never `~/.docker`,
  which outlives stop/Remove/Disable).
- **`-p 127.0.0.1:${HOST_PORT}:<internal>`** — loopback-only publish; the
  internal port comes from the runbook.
- If the image reads a different env name, bridge env→env at the top:
  `export OTHER_NAME="$NVIDIA_API_KEY"` (never argv, never a file).
- **`-e NAME` bare** (argv is world-readable); the key rides the login
  stdin pipe only.
- **`-d`, no `--rm`** — managed containers are **stopped, never removed**:
  stop parks them with weights loaded; `--rm` throws the cache away.
- Cache under `$SERVICE_DIR`, owned by the **container's** uid: the
  runbook states it when it matters; otherwise derive it post-pull with
  `docker inspect --format '{{.Config.User}}' <image>` (empty or `root`
  ⇒ runs as root, no chown needed; a NAMED user can't be resolved
  without running the image — default `1000`). Getting it wrong is the
  cache-empty symptom: the container can't write the mount, weights leak
  into the writable layer and die on recreate (or the image crash-loops
  on Permission denied). Never `777` — world-writable cache on a
  multi-user host. The mount TARGET comes from the runbook.
- Cells need **no auth header** against local endpoints — the credential is
  a pull key that never enters your kernel.

## Failures

A failed start/stop flips the endpoint **FAILED** (transcript on the
endpoint panel — never echoed into cell errors; ask the user to read it
there) and your cell errors with the daemon's one-line cause. FAILED is
**sticky**: further cells fail fast until the user presses Stop or you
re-register (byte-identical re-register also clears it). If a stop is stuck
(exit 0 but the port never frees), removal is refused while the port is
bound — recover out-of-band; the daemon absorbs the freed port on its next
probe. A first-ever cold start downloads image + weights — minutes, once;
the cell streams the phase lines live and the endpoint detail view streams
the full script output, so let it run.
