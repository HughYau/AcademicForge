# Building a Modal environment

You're here because the env you need isn't in the `compute_details` ledger
yet — first run on this workspace, or the env's definition changed in this
release. The fix is one `compute_provider` cell, but it helps to understand
why that cell runs where it does.

## Why a separate kernel

Building an image and populating a weight volume both require holding the
user's Modal credential and making arbitrary SDK calls with it. The job
surface — `host.compute.create()` — deliberately doesn't have that: it's a
narrow, parameterised path where the user approves a specific tier and the
host does the SDK work on their behalf. Letting the same surface also build
arbitrary images would mean either widening that approval to "anything the
SDK can do" or asking for a second approval that says exactly that. The
architecture takes the second option and gives it its own kernel.

So the `compute_provider` kernel is a Python shell where `modal` is
authenticated and you can call anything the SDK offers, fenced by its own
one-time approval card and a couple of guardrails that keep it from
becoming a back door to the job surface (no `gpu=`, thirty-minute timeout
cap on CPU sandboxes). The control-plane kernel (the `repl` tool) never
sees the token. What crosses back is a string — the image reference — and
that's all the job surface needs.

In practice this means env setup and job submission are different tasks
with different validation. You build the image, confirm it built, record
it; *then* you run the job. Folding them together makes both harder to
debug when something goes wrong, and it makes the user's two approvals
harder to reason about because they arrive intertwined.

## What `build_env()` does

The bundled environments live in `envs/*.py` next to this file. Each is a
plain Python module the env author has already run against real Modal: a
`META` dict describing what's inside, a `build()` that returns the
`modal.Image` chain plus the volumes and env-vars the job will want, and
optionally a module-level `HYDRATE = ('bash', '-lc', '…')` tuple that does
one-time weight downloads into a persistent volume. There's no spec to
translate — the file *is* the SDK code.

`build_env(name)` is pre-bound in the `compute_provider` kernel alongside
`modal` and `app`. It exec()s the named file, calls `build()`, builds the
image on Modal's CPU infrastructure, and hands back everything the ledger
block needs:

```python
# ── compute_provider tool ──
r = build_env('proteomics_jax_gpu')
print(r)
# → {'image': 'im-…', 'spec_sha': 'a1b2…',
#    'volumes': {'/root/.cache/colabfold': 'claude-science-colabfold-weights', …},
#    'env': {…}, 'gpu_default': 'A100',
#    'egress_domains': ['api.colabfold.com'],
#    'hydrate_defined': True, 'hydrated': True}
```

`spec_sha` is the content hash of the env file — record it in the ledger
and a future session can tell whether the cached image still matches what
this binary ships. Pass `hydrate=True` to also run the env's weight
download (idempotent — safe to re-run). `list_envs()` returns
`{name: META}` for every bundled file, so it's the cheap way to find which
env carries the packages you need.

`egress_domains` is the env author's declaration of the outbound hosts the
env's documented commands need at *job* time, beyond Modal's own
control/blob planes (never hydrate-time hosts — `HYDRATE` runs in this
kernel, not in the job sandbox). Record it as an `egress:` line in the
ledger block so a future session can reuse the cached image without
re-running `build_env()` to rediscover the list.

Everything `build_env()` produces is scoped to ONE Modal **Environment**:
the one this kernel runs in (`MODAL_ENVIRONMENT` when the provider has one
configured in *Settings → Compute → modal → Environment*, otherwise the
user's Modal default). The ledger block you write therefore implicitly
belongs to the environment that built it — its `image: im-…` id and the
volumes its `build()` resolved exist *only there*. If the user later
changes the provider's Environment, treat those ledger entries as stale
for the new namespace: re-run `build_env(...)` (and `HYDRATE`) there
rather than retrying a `not_found` `im-…` id. When in doubt, ask before
you build: `compute_provider_config()` (in this kernel — there is no
`repl`-tool twin) returns the provider config this kernel is bound to,
and raises `ComputeProviderConfigStale` if the provider's Environment,
Default app or Network Restrictions mode changed after this kernel
started — those are
the fields a kernel binds at spawn and cannot follow, so the remedy is
always a fresh `compute_provider` kernel (other Settings edits, e.g. the
timeout default or the allowlist's domain list, don't raise).
`build_env()` makes the same check itself before building anything.

There's no `host.compute` or `host.skills` here — those belong to the
control-plane kernel (the `repl` tool). The two share a working directory
but not memory; pass values between them via workspace files when needed.

## Envs that need a secret

If an env's `META['needs_secrets']` lists credential names, `build_env()`
resolves them automatically via `credentials_get()` when you don't pass
`secrets=` explicitly. (None of the bundled envs currently require this;
the hook exists for envs that pull from authenticated registries or
license-gated channels.) The `compute_provider` kernel can read the
credential store the same way the analysis kernel can — that's disclosed
on the kernel approval card.
Pass `secrets={...}` explicitly only if you need to override what's stored.

That's secrets needed at *build* time. Gated *weights* — typically an
`HF_TOKEN` for a license-accept Hugging Face repo — are a job-time
concern: build with `hydrate=False`, then download in a regular
`submit_job(credentials=['HF_TOKEN'])`. That path resolves named
credentials host-side and forwards them into the remote env, with the
`byoc_submit` card showing `→ forwards credential: HF_TOKEN` so the user
sees what's being sent.

## Recording the result

```python
# ── repl tool ──
if 'hydrate_error' in r:
    print(f"hydrate failed (image {r['image']} built ok): {r['hydrate_error']}")
else:
    compute_details({'provider': 'byoc:modal', 'mode': 'append', 'text': f"""
### env:{name}@{r['spec_sha']}
image: {r['image']}
built: {iso_today}
volumes: {r['volumes']}
egress: {' '.join(r.get('egress_domains') or [])}
"""})
```

The `egress:` line is `META['egress_domains']` written out
space-separated. For a **bundled** env it is optional: name the env
(`provider_params.modal.env`, or this block's `### env:<name>@…` header)
and the host reads the declaration from the SHIPPED env file at every
submit, so a rebuild's new `im-…` id can never sever it. For an
**ad-hoc** env (`build_env(path=…)` on a file you wrote) this line is the
only carrier — record it. Either way the declaration is a *request,
never an authority*: the host re-validates, caps and discloses every
token on the `byoc_submit` card ("declared by this env" — a card a
standing grant never skips), and ignores it outright under the
provider's "No network" mode. When a fenced job dies on a host the env's
documented commands always need (the result's `[egress]` line names it),
the durable fix is adding that host to `META["egress_domains"]` and
resubmitting on a fresh handle — the sandbox that failed keeps the fence
it was born with. SKILL.md's egress section is the authoritative
reference for the merge, the card rows and the hints.

This is the only state that survives the session. The next run reads it,
sees the hash matches, and goes straight to `compute.create()` — no kernel
card, no rebuild. Builds run on Modal's Linux infrastructure regardless of
the user's OS, and layer pulls and pip downloads happen Modal-side, so the
only egress this kernel itself makes is gRPC to Modal's control plane.
That's also why `hydrate()` spins a short-lived CPU sandbox rather than
downloading locally: a multi-gigabyte weight fetch happens inside Modal's
network, not through the local allowlist — and it terminates that sandbox
in a `finally`. Match that shape for any sandbox you spin yourself (a
smoke probe, an ad-hoc fetch): create, `exec`, `sb.terminate()` in a
`finally`.

## When the bundled env isn't right

Sometimes you need a package the bundled envs don't carry, or a version
they pin conflicts with what you're doing. The env files are real Modal SDK
code, so the path is the same one the env author took: write the chain,
build it, run a smoke probe.

For a small tweak, read the bundled file, edit it, and point `build_env()`
at your copy:

```python
# ── repl tool ──
src = host.skills.read('remote-compute-modal', 'envs/proteomics_gpu.py')['content']
src = src.replace('"transformers==4.46.3"', '"transformers==4.48.0"')
open('proteomics_gpu_tx448.py', 'w').write(src)   # workspace cwd
```

```python
# ── compute_provider tool ──
r = build_env('proteomics_gpu_tx448', path='./proteomics_gpu_tx448.py')
```

For something genuinely new, `envs/proteomics_jax_gpu.py` is the reference shape.
The contract is small: a top-level `META` dict, a `build(*, secrets={})`
that returns `(modal.Image, {mount: Volume}, {env_var: value})`, and
optionally a `HYDRATE = (argv...)` tuple — `build_env(hydrate=True)` runs
it once in a CPU sandbox with the volumes mounted to populate weights.
Everything between `import modal` and `return img, vols, env` is whatever
Modal SDK code the build needs — `from_registry`, `pip_install`,
`run_commands`, `env`, `apt_install`. Modal's docs are the docs; there's no
product-specific layer to translate through.

If a build fails, the log tail is in the cell output. The usual culprits
are version pins that no longer resolve together (read the
`ResolutionImpossible` carefully — it names both sides of the conflict),
CUDA/cuDNN mismatches between the base image and a wheel built for a
different version (jax and torch are both sensitive to this), and packages
whose CUDA wheels live somewhere other than PyPI (`find_links=` is the
escape hatch — `envs/proteomics_rfd_diffdock_gpu.py` shows it for DGL and
the torch-cluster/scatter/sparse PyG extension wheels). No
image reference is produced on failure, so the ledger stays clean
and a retry is just re-running the cell.

## Tool recipes that survive the egress fence

Some tools fetch weights or databases from hosts the default allowlist
never carries; do that fetch where there is no fence — **(a) bake** it at
image build, or **(b) stage** it from this kernel into a Volume — and the
job runs with no network (the rule: SKILL.md → "Skill-driven jobs and
the fence"). Use only a downloader the image you run on installs
(`debian_slim` has neither `wget` nor `curl`); the two bake recipes were
live-proven 2026-06-28 under `block_network=True`, the staging snippets
were not.

### Pattern (a) — bake at image build: LigandMPNN, ESM-2

LigandMPNN (`get_model_params.sh` → `files.ipd.uw.edu`, ~120 MB; the
script is wget-only):

```python
img = (modal.Image.debian_slim(python_version="3.11")
  .apt_install("git", "wget", "build-essential")
  .env({"CC": "gcc", "CXX": "g++"})   # ProDy builds from source on py3.11
  .pip_install("torch", "numpy", "biopython", "ProDy", "ml_collections",
               "dm-tree")
  .run_commands(
    "git clone https://github.com/dauparas/LigandMPNN.git /app/ligandmpnn"
    " && git -C /app/ligandmpnn checkout 26ec57ac976ade5379920dbd43c7f97a91cf82de",   # pinned 2026-06-28
    r"sed -i 's/np\.int\b/np.int64/g' /app/ligandmpnn/openfold/np/residue_constants.py",
    "cd /app/ligandmpnn && bash get_model_params.sh ./model_params",
  ))
```

ESM-2 / fair-esm (`torch.hub` → `dl.fbaipublicfiles.com`; bake the
8M–650M checkpoints, ≤2.5 GB — the ~11 GB `esm2_t36_3B_UR50D` goes down
pattern (b) into a Volume mounted at `/opt/torch` instead):

```python
img = (modal.Image.debian_slim(python_version="3.11")
  .pip_install("torch", "fair-esm")
  .env({"TORCH_HOME": "/opt/torch"})
  .run_commands(
    "python -c 'import esm; esm.pretrained.esm2_t33_650M_UR50D()'",
    # fair-esm does not hash-verify its downloads — it fetches BOTH the main
    # checkpoint and the contact-regression head; digests computed 2026-06-28.
    "echo 'ea9d0522b335a8778dea6535a65301f10208dece28cd5865482b0b1fc446168c  "
    "/opt/torch/hub/checkpoints/esm2_t33_650M_UR50D.pt' | sha256sum -c",
    "echo '8ffe6edbd4173dc8d45c2cd5cb27d43aad77ec26b4c768200c58ae1f96693575  "
    "/opt/torch/hub/checkpoints/esm2_t33_650M_UR50D-contact-regression.pt'"
    " | sha256sum -c"))
```

The job loads from the image (`/app/ligandmpnn/model_params`,
`/opt/torch`) and needs no network; declaring the host in
`META["egress_domains"]` is only for a fetch that truly must happen at
job time.

### Pattern (b) — stage from this kernel into a Volume: AF2 params

The canonical staging sandbox, shown for the AlphaFold2 parameters —
`storage.googleapis.com` is the host the fence deliberately never
carries (the bundled `proteomics_jax_gpu` env's `HYDRATE` is this exact
pattern pre-written: `build_env('proteomics_jax_gpu', hydrate=True)`):

```python
img = modal.Image.debian_slim(python_version="3.11").apt_install("wget")
app = modal.App.lookup("egress-staging", create_if_missing=True)
vol = modal.Volume.from_name("af2-params", create_if_missing=True)
sb = modal.Sandbox.create("bash", "-lc",
    "wget -q -O /params/af2.tar https://storage.googleapis.com/alphafold/"
    "alphafold_params_2022-12-06.tar"
    # digest computed 2026-06-28
    " && echo '36d4b0220f3c735f3296d301152b738c9776d16981d054845a68a1370b26cfe3  /params/af2.tar' | sha256sum -c"
    " && tar xf /params/af2.tar -C /params && rm /params/af2.tar",
    image=img, volumes={"/params": vol}, timeout=1800, app=app)
try:
    sb.wait()
    # wait() does NOT raise on a nonzero exit — surface the gate's verdict.
    if sb.returncode != 0:
        raise RuntimeError(f"staging failed (rc={sb.returncode}): "
                           + sb.stderr.read())
finally:
    sb.terminate()
```

The job then mounts the volume and runs with no network. An MMseqs2
database build is the same shape, with the staging image additionally
baking the official mmseqs static binary (the in-job `mmseqs databases`
download is the path that does NOT work under an allowlist).
