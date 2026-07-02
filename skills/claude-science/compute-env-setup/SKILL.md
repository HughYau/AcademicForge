---
name: compute-env-setup
description: Set up a compute environment on a remote provider so Claude Science jobs can run there. Covers direct SSH/conda hosts, Slurm clusters, container-via-bridge runners, and managed-API providers (Modal, GCP, RunPod). Use when standing up a new provider, porting an env to a different backend, adding a tool that needs its own software stack, or wiring weight caches. Triggers on "new compute provider", "set up env on", "port env to", "build GPU image", "weight cache", "compute_details", "conda env on the box", "apptainer on slurm".
license: Apache-2.0
---

# Setting up compute environments on a remote provider

## Overview

What's invariant across every backend is what a job *needs*: a software stack (specific package versions, often with load-bearing install ordering), possibly some large model weights placed where the tool will find them, and a resource shape. What varies — a lot — is how a given provider materialises those three things and how an env name gets resolved to them at submit time. This skill is about keeping one declarative spec that says *what* the environment is, and treating *how it gets built and addressed on this provider* as something you figure out once per provider. The work ranges from minutes (another conda env on a host that has ten) to days (GPU image + weight cache + egress on a fresh backend), and most of the long tail is diagnosing why the documented invocation doesn't work even though every import succeeds.

**Before building anything:** `compute_details({provider, mode:"read"})`. The env, or a near-match you can extend, may already exist. The doc you get back is also where you'll record what you set up.

## Provider shapes

These are not exhaustive and they blend at the edges (a Slurm node can run Apptainer containers built from the same Dockerfile a cloud backend uses). The point is to recognise which shape you're in, because that determines what "build", "register", and "resolve" mean.

**Direct SSH host (conda or venv).** You have a shell on the machine. There is no image, no runner script, no renderer — *you* are the renderer: read the spec's `pip_phases` and run them in order after `conda create -n <name> python=<X>`. (When the spec's `base` is a Docker image string, treat it as documentation of the python + CUDA versions you need, not something to pull.) Weights live in scratch or home; download once, point the tool's cache env var there. The env name *is* the conda env name — name it exactly what you want `--env` to accept, there's no aliasing layer. `submit_job` activates it (`conda run -n <name> …`) and runs. "Registering" is implicit: once the host is added as a Claude Science SSH provider, its probe lists conda envs, and you append a `### env:` block to `compute_details` so the next agent knows what's there without re-probing. Lowest ceremony; often right for a personal GPU box.

**Scheduler cluster (Slurm, PBS, LSF).** Shared filesystem, login node, compute nodes via `srun`/`sbatch`, usually no root. Software is `module load <name>` or Apptainer/Singularity containers in a shared path. For containers: `apptainer pull <name>.sif docker://<ref>` if the image was built elsewhere; `apptainer build --fakeroot <name>.sif <name>.def` only if the cluster enables unprivileged user namespaces (many don't — build off-cluster and `pull`). Set `APPTAINER_CACHEDIR`/`APPTAINER_TMPDIR` to scratch first or the layer cache will blow your home quota. For modules: write the modulefile under a *personal* tree (`$HOME/modulefiles/`) and `module use $HOME/modulefiles` in the job preamble — you almost certainly can't write the system MODULEPATH. Weights go in shared scratch; note that scratch is usually purge-on-idle, so record the purge window and consider mirroring to a project/group quota. Tier becomes scheduler directives, and on most clusters `--account`, `--partition`, and `--time` are mandatory alongside `--gres=gpu:<type>:1 --cpus-per-task --mem`. Compute nodes often have **no internet** — egress is not a fallback here; pre-stage everything from the login or data-transfer node.

**Container via bridge runner.** The compute happens inside ephemeral containers launched by some service (a sandboxing API, Kubernetes, a cloud batch system), but Claude Science talks to it through a small persistent *bridge host* — an SSH-reachable box that holds credentials and a runner script. Building means producing a container image (Dockerfile → registry, or the service's image builder) and caching it where the service can pull it. Weights are mounted read-only from object storage or a volume the service supports. The runner script (`advanced_runner.py` is the worked example) holds a literal `ENV_TABLE = {"<name>": {"image": <ref>, "tier": …, "mounts": …, "egress": …}}` and translates `--env <name>` into the service's launch call. "Registering" is adding an entry to that table and redeploying the script. This shape exists because the service's own API is either not directly reachable from Claude Science or needs credentials you don't want in every agent process.

**Managed API with native adapter (byoc).** Modal, RunPod, a cloud Batch service — anything where Claude Science talks to the provider's SDK directly instead of going through a bridge host. Each provider's adapter ships a directory of bundled env definitions that *are* SDK code (not a spec to translate); you build one by calling `build_env(name)` inside the **`compute_provider` kernel** — a confined Python shell where the SDK is already authenticated. What comes back is the provider's opaque image reference plus any volumes the env mounts; those strings are all the job surface needs. Weights populate inside the same kernel so multi-gigabyte downloads happen on the provider's network rather than the local allowlist. Name resolution is the same `### env:<name>@<specHash>` ledger block as everywhere else — the content hash means a definition change is a cache miss and an unchanged one warm-reuses without rebuilding. Once the adapter exists, this shape has the least friction of any of them.

The honest answer to "which shape should I use" is usually "the one this provider already is." You're rarely choosing; you're recognising.

## The declarative spec

The portable artefact is a dict describing what the env *is*, independent of how any backend builds it. The same `ENVS["proteomics-gpu"]` entry renders to a Dockerfile, an Apptainer definition file, or a sequence of shell commands run over SSH — because every field maps to something each of those understands. (byoc providers ship their env definitions as SDK-native code and skip this rendering layer; the spec below is for the other shapes.)

| Field | Meaning | Why it's portable |
|---|---|---|
| `base` | Starting image / interpreter+CUDA versions | `FROM`, `from_registry()`, `Bootstrap: docker`; on bare conda, read it as the python+CUDA versions to `conda create` |
| `system_pkgs` | OS-level packages | `apt`/`yum`/`apk` in a container; on a no-root host, `conda install -c conda-forge` covers a subset — if not, that dep has to come from a container built off-host |
| `pip_phases` | **Ordered** `list[list[str]]` — each inner list is one `pip install` call | Every backend runs pip; ordering is the load-bearing part |
| `env` | Baked environment variables | `ENV`, `%environment`, or `conda env config vars set` |
| `run_commands` | Escape-hatch shell | `RUN`, `%post`, or just run it over SSH |
| `shim_files` | Small files to place in the env | `COPY`, `%files`, or `scp` |
| `weight_dirs` | `{name: {path, source, gated?, auth_hint?}}` | Declared once; *where* they live is provider-specific |
| `import_names`, `gpu_tests`, `cli_checks` | Smoke probes | Run inside the env regardless of how it was built |

`pip_phases` ordering **is** the fix for every "package A drags B to the wrong version" problem — e.g. `chai_lab` pins a CPU-only torch wheel, so install `["torch==2.3.1"]` as the phase **before** it: each phase is its own pip invocation, and pip leaves an already-satisfied requirement alone unless asked to upgrade.

A clean spec renders unchanged through every renderer you have. When you find yourself adding a field only one backend understands, that field belongs in a per-provider deploy table, not the spec. `references/envs_reference.md` has the worked examples; note that paths there (`/app`, `/opt`, `/datavol`) are container conventions — on a bare host or Slurm node, read them as "wherever you cloned the repo / put the weights" and substitute.

## BYOC providers — building via the `compute_provider` kernel

On a `byoc:` provider, you're not writing a Dockerfile and pushing to a
registry. You call `list_envs()` then `build_env(name)` in the
`compute_provider` tool — a confined Python shell where the provider's SDK
is already imported and authenticated — and carry the returned image
reference back to record in `compute_details`. The first cell raises a
one-time kernel approval card; the kernel rejects `gpu=` and clamps CPU
sandboxes so it isn't a back door to the job surface. `terminate()` any
sandbox you create ad hoc in that kernel before you move on.

`remote-compute-<provider>/env-setup.md` has the architectural rationale
for why this is a separate kernel and the provider-specific calls.

## Weights

The decision is size × access pattern, not which backend you're on — though the backend determines the mechanics.

Small (<~500 MB) and read by every job: bake into the env at build time (image layer, conda env tree, or `.sif`). The extra build size is cheaper than a separate weight path or a runtime download.

Large (>~1 GB) with a cache env var the tool respects: put it somewhere persistent the job can see and point the env var there. On a direct SSH host that's a scratch directory. On Slurm it's shared scratch (mind purge policy). On container backends it's a read-only volume/squashfs mount, which means tools that write lockfiles next to the weights need a `/tmp` overlay — see the diagnosis table.

Neither applies: let the tool download at runtime — but on backends where compute nodes have no internet (most Slurm), that isn't available, so you populate from a node that does and stage the tree across.

Populate by running the **tool's own loader** with the cache var pointed at writable scratch (hand-curling produces a layout the tool may not recognise). If the loader needs a GPU and the only GPU nodes lack egress, populate on a machine that has both and rsync the tree in. Before freezing/snapshotting, verify completeness *from the tool's perspective*: run the actual inference entrypoint once against the staged dir (some tools check a marker file, some lazy-fetch a sub-tree only on first inference) and `du -sh` every subdir — empty means a swallowed download error.

## Validation

Three levels, and the gap between them is where most of the debugging time goes.

*Import works* — `python -c "import chai_lab"` returns 0. Necessary, cheap, and catches almost nothing interesting.

*Kernel-dispatch witness* — a tiny seeded forward pass that prints a sentinel line with output shape, device name, and a non-emptiness check. This catches "torch sees the GPU but the kernel was compiled for an older SM", "the import worked but the compiled extension's `.so` isn't on the loader path", "the model loaded but inference writes to a read-only cache". Keep the witness in `WORKLOADS[<name>]` as `{inputs, cmd, expect: regex}` so the same probe runs on every backend.

*Agent following the skill doc* — the validation that actually matters and the one that's easy to skip. Spawn a sub-agent per env, have it read the relevant tool skill and `compute_details(provider)`, submit a job that exercises the documented invocation *verbatim*, and diff what the doc claims against what happened. This is where you find out the doc says `--ligand` but the flag is `--ligand_description`, or the weights row points at a path that has the right files but is missing the completion marker the tool checks for, or the `--config` argument silently overwrites every other CLI flag. This pass routinely finds blocking bugs on envs whose import-level smokes have been green for weeks.

The witness is cheap enough to run on every build. The agent-follows-doc pass is expensive, so reserve it for the two moments doc and env can drift apart — after any env rebuild (image, conda env, `.sif`, modulefile) or doc edit — and before declaring the env ready.

## Diagnosing failures

When a documented invocation doesn't work, the temptation is to patch — add a flag, symlink a path, retry. The better move is to ask what the failure tells you about which *layer* is wrong: the spec, the build, the weight cache, the resolution mechanism, or the doc. Rows below mentioning mount/entrypoint apply to container/apptainer shapes; the rest are universal.

| Symptom (grep-able) | Layer | What's actually wrong → fix |
|---|---|---|
| `no kernel image is available for execution` | build/spec | torch/jax compiled for older SM than this GPU. Record `sm_range` per env and route the job; rebuild only if no compatible hardware exists |
| `AttributeError: module 'numpy' has no attribute 'int'` | spec | Vendored dep predates numpy 1.24's alias removal (deprecated in 1.20, removed in 1.24). sed `np.int/float/bool/object` → builtin on the offending file; don't delete the importing code (masks the symptom, breaks `_modules`-style refs) |
| `ImportError: libfoo.so: cannot open shared object file` | build | Compiled-ops `.so` installed but not on the dynamic-linker path. `find / -name 'libfoo.so'` → add its dir to `LD_LIBRARY_PATH` (often two libs: the ops `.so` + `libnvrtc.so.12`) |
| `ModuleNotFoundError` for a package not in your spec | spec | A `--no-deps` install skipped a new runtime dep. Read the package's `pyproject.toml` `dependencies` and add the missing ones as an explicit phase |
| Wrong torch/numpy after install | spec | A later package's pin won the resolve. Add a `force_reinstall + no_deps` snap-back phase after it |
| Tool re-downloads despite populated weight dir | weights | `du -sh $CACHE_VAR` first. 0 B → populate step swallowed an error. Non-zero → tool checks a completion marker file, not the weights; bake that too |
| `OSError: Read-only file system` under `$CACHE_VAR` | weights (container) | Tool writes locks/`refs/` next to weights but the mount is RO. Symlink leaf blobs into writable `/tmp/<cache>` and export the var there |
| Mount step fails (`init_failure`, `not empty`) | weights (container) | Mount target collides with a path the base already populates. Mount at a path the build doesn't touch |
| `--model_dir X` has no effect | doc/tool | Tool loads `--config <yaml>` *after* argparse and overwrites CLI flags. Either patch the yaml at build time or document "copy + edit the yaml" |
| `ValueError: current limit exceeds maximum limit` | build vs host | Hard-coded `setrlimit(NOFILE, (N, hard))` exceeds the runtime's hard limit. sed `(N, hard)` → `(min(N, hard), hard)` |
| `Permission denied`, command never runs | build (container) | Upstream base sets a non-root user or wrapper that pre-empts your command. Override to a uid that can write the workdir and clear any inherited entrypoint/runscript |
| 80-way thread storm on a 4-CPU tier | exec | `os.cpu_count()` returns the host's cores, not your allocation. Export `OMP/MKL/OPENBLAS_NUM_THREADS=<tier.cpus>` before exec — every backend needs this |
| First job slow, every subsequent job equally slow | build | Expensive precompute (e.g. SO(3) lookup tables) runs at job time and the workdir doesn't persist. Run it once at build time so the `.npy` lands in the env tree |
| Job COMPLETED but output dir empty | exec | The wrapper that writes the phase marker never ran — often `#!/bin/bash` on a minimal runtime that only ships `/bin/sh` |

When you hit one of these, append the symptom and the fix to that provider's `compute_details` so the next agent doesn't rediscover it — when the symptom is a property of the provider, not of this project's data.

## compute_details — recording what's set up

Per-provider durable markdown. It documents what exists; it is not the resolution mechanism. The block is for the *next agent reading this provider cold* — what `--env` values exist, how each resolves on this provider, what was validated when. Read with `compute_details({provider, mode:"read"})`; append with `mode:"append"`; swap a stale line with `mode:"replace"` + `old_text`.

```
### env: proteomics-gpu
how: conda env "proteomics-gpu" on host          # on Slurm: apptainer $SCRATCH/images/proteomics-gpu.sif
                                                 # on a bridge runner: <runner-path>, image <ref>
tier: {cpus: 8, mem_gib: 64, gpus: 1}            # on Slurm also: partition, account, time, gres string
weights: CHAI_DOWNLOADS_DIR=/scratch/weights/chai (12 GB; purge-window 30d)
sm_range: sm_80..sm_90
validated: <date> (kernel-witness + agent-follows-doc clean)
gotcha: <any diagnosing-failures row hit on THIS provider>
```

## Reference guides

- `references/envs_reference.md` — the Claude Science envs as worked examples of the spec: base, pip_phases with the *why*, weight mechanism, the `WORKLOADS[name]` witness command, gotchas. For any provider shape, this is the recipe — the spec fields are what you render (to a Dockerfile, a provider's image API, an Apptainer def file) or run by hand (direct conda/SSH).
- `remote-compute-modal/env-setup.md` — the Modal-specific build path: `list_envs()` / `build_env()` in the `compute_provider` kernel, volume hydration, GPU-tier selection, and how to write a new env file when the bundled set doesn't cover what you need.
