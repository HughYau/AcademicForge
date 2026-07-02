---
name: remote-compute-modal
description: Run GPU jobs on the user's own Modal account via host.compute.create('byoc:modal', ...). Covers the create→submit→wait_for_notification flow, the compute_provider kernel for env setup, image/volume resolution, and the two approval cards. Load once you've decided to dispatch to Modal.
license: Apache-2.0
---

You're dispatching to the user's Modal account: containers spin up in Modal's
cloud, on hardware you name in plain terms (gpu/cpu/memory/timeout), under
their workspace, on their bill. That's the reason there are
two approval cards rather than one, and the reason the env-setup surface is
a separate kernel rather than something you can call inline from the
control-plane kernel: each card is the user consenting to a specific,
bounded use of their credential, and the architecture keeps those grants
legible by keeping the surfaces apart.

If `compute.create('byoc:modal', …)` returns `unknown provider 'byoc:modal'`,
Modal isn't enabled in this install — ask the user to enable it under
*Settings → Compute → Modal* (or surface the prompt; you can't enable it for
them).

For first-time environment setup, see `env-setup.md` in this skill
directory — it walks through driving the `compute_provider` kernel to
build and record images.

## Two timeouts, one timeline

Modal has two deadline timers. Both live INSIDE the sandbox, and neither
can cost you the outputs of a job that ran. The timeline every job runs
on:

1. Container life starts at sandbox creation — staging the inputs counts
   against it, so a big upload spends container time before the job runs.
2. The job runs. If it exceeds its own budget (the job timeout below), it
   is TERMed there.
3. Near end of container life — one harvest margin before the provider
   destroys the sandbox — the in-sandbox **harvest watchdog** TERMs
   whatever is still running. It runs on the sandbox's own clock, so a
   wrong desktop clock or a slow upload can't make it fire late.
4. After any TERM there is a grace window for checkpoint-on-TERM handlers
   to flush, then the process group is stopped.
5. Whatever is under `./out/` (plus the logs) is tarred and staged
   UNCONDITIONALLY — on success, timeout, failure, and crash alike — and
   harvested back into the workspace. Staging is unconditional; delivery
   isn't. If the stream is refused or gives up (`result_rejected`,
   `harvest_failed`), the staged copy waits on the sandbox, and a third,
   post-job timer — the **idle watchdog** — terminates it after ~30 min
   of inactivity. See "When the job fails".

The **container timeout** (`provider_params.modal.timeout`) is how long
the sandbox lives; omitted, it fills from the Settings default for this
provider (*Settings → Compute → Modal*; ceiling: Modal's 24 h platform
lifetime, minus the staging margins — 85,500 s). The **job timeout**
(`timeout_seconds` on `submit_job`) is an optional runaway guard for one
job; omitted, it defaults to the container's remaining life minus the
harvest margin. Name one when you know the job's budget — a hung job then
costs that budget, not the whole container, and the warm container
survives for the next submit.

A deadline-ended job lands as `status: 'timed_out'` — not a generic
failure — with its partial outputs already harvested, plus a note saying
the deadline (not the workload) ended the run and suggesting the remedy:
a larger `timeout_seconds`, or resuming from a harvested checkpoint. A
deadline ends the run, never the results.

## Two surfaces, one provider

You reach Modal two ways. They share confinement and credentials but answer
different questions, and confusing them is the most common way to waste a
turn.

`host.compute.create('byoc:modal', provider_params={'modal': {...}})` is
the **job surface**. It runs in the `repl` tool — same as
`remote-compute-ssh` — and is what you use for anything with
inputs/outputs you want harvested into the workspace, anything on a GPU, and
anything long enough that you'd want to reattach if the daemon restarts. The
call itself is a stateless constructor — the **tier card** (provider, image,
`1× A100-40GB · 8 CPU · 32 GB`, container timeout, volumes) and the actual
Sandbox creation both happen on the first `submit_job()`.
`submit_job`/`result`/`call_command`/`attach_job`/`close` then work exactly
as for SSH: `.result()` is **non-blocking** — the daemon's poller probes the
sandbox, harvests `out.tar.gz` into `hpc/<jobId>/`, and emits a
`compute_done` notification when done. To wait, exit the cell after
`submit_job` and use the `wait_for_notification` brain-tool. What reaches
the remote is what was in the workspace files you named, and what comes
back lands under `hpc/<jobId>/` through the same hardened extractor.

`compute_provider({'provider': 'modal', 'code': '…'})` is the **environment
surface** — a Python shell with the user's Modal SDK already authenticated,
running in its own confined process. Use it to *prepare* compute: build
container images JIT in the user's workspace, populate model-weight volumes
by running the downloads on Modal's own infrastructure (so wide-internet
fetches never traverse the local allowlist), check what assets already
exist, run a short CPU smoke probe. Its first cell in a session fires the
**kernel card** — *"environment setup — build images, populate volumes, CPU
probes ≤30 min; GPU jobs ask separately"* — and once granted, subsequent
cells in this kernel's lifetime (idle-timeout ~15 min) run without further
prompts. The kernel will reject `gpu=` on `Sandbox.create` and clamp
`timeout` to ≤30 min — the kernel's own probe budget, separate from the
job surface's container timeout. It's a redirect to the job surface, not
a fence; you've already been handed the credential. **Terminate every
sandbox you create here** — `sb.terminate()` in the same cell, in a
`try/finally` if you `exec` in between (`build_env`'s hydrate models
this). Nothing reaps it mid-session: the idle timeout kills the
*kernel*, never your sandboxes — the ≤30-min clamp only bounds how long
a forgotten one bills.

The shape of a good run is: read what's already known about this workspace,
decide whether the env you need exists, build it via the `compute_provider`
kernel if it doesn't, then run the actual job through `compute.create()`.
The two cards appear at most once each per session — and on a warm second
session with a project-level grant, neither.


## Workflow

Every `host.compute.*` call here runs via the **`repl` tool**; the
`compute_provider` kernel is reached via the **`compute_provider` tool**.
Neither is the `python` tool. All three share your workspace directory but
not memory — pass data through files.

Start with `compute_details({provider: 'byoc:modal', mode: 'read'})`. Below
the orientation line is the per-workspace ledger — `### env:<name>@<spec_sha>`
blocks recording images that already exist in this user's Modal workspace,
the volumes they pair with, and any free-text notes a previous session left.
The `spec_sha` is the content hash of the env's source file in this binary,
so a ledger entry whose hash matches is one you can use without rebuilding:
pass its image ref straight to `compute.create()` and the kernel card never
appears. A mismatch means the env definition changed in this release — the
old image still works but isn't what the current env file describes, so
treat it as absent.

If what you need isn't in the ledger, build it in a `compute_provider`
cell. Two helpers are pre-bound there alongside `modal` and `app`:

- `list_envs()` → `{name: META, …, '_envs_dir': path}` for every bundled
  env (packages, GPU tier, secrets it needs)
- `build_env(name, *, hydrate=False)` → builds the image, returns
  `{'image': 'im-…', 'spec_sha', 'volumes', 'env', 'hydrate'}`

To inspect what an env actually installs (the `modal.Image` chain) before
building, read the source from the **control-plane kernel** (a `repl`
cell) — it's a skill asset:

```python
# repl tool
print(host.skills.read('remote-compute-modal', 'envs/proteomics_jax_gpu.py')['content'])
```

Don't `find` for it from bash — the path differs across builds.

```python
# compute_provider tool, provider='modal'
need = {'transformers', 'torch'}
envs = list_envs()
print({n: m for n, m in envs.items()
       if not n.startswith('_') and need <= set(m.get('packages', []))})
# → {'proteomics_gpu': {'packages': [...], 'gpu_default': 'A100-80GB', ...}}

r = build_env('proteomics_gpu', hydrate=True)
print(r['image'], r['spec_sha'], r['volumes'])
```

Carry `r['image']` (the `im-…` reference, NOT the env name) back to the
control-plane kernel (a `repl` cell) and pass it to
`provider_params.modal.image` — and, for a bundled env, its NAME as
`provider_params.modal.env`: the host then reads the env's
`META["egress_domains"]` from the SHIPPED file at every submit, so the
declaration survives rebuilds (a pointer into the shipped catalog, not a
power). The two kernels share a working directory but not memory, so the
simplest handoff is a workspace JSON file:

```python
# compute_provider tool — last line of the build cell
import json; json.dump(r, open('built_env.json', 'w'))
```

Append a `### env:<name>@<spec_sha>` block to `compute_details` so the
next session reads the `im-…` ref straight from there and skips the
`compute_provider` cell entirely. **Pass `r['image']` (the `im-…` ref) to
`provider_params.modal.image`.** The adapter will resolve a bare env name
from the ledger as a fallback, but that's brittle — the ledger entry can
be stale or absent. Treat the build as its own task with its own validation;
don't fold it into a job submission. See `env-setup.md` for ad-hoc patches
and gated weights.

For a quick inline call (no inputs, output is just stdout), use
`submit_job` with no `inputs`. The `compute_done` notification payload
carries `status` / `exit_code` / `featured_files`, plus `error_kind`,
`system_hint`, and `deadline_fired` when set — read those disclosures
from the notification itself (a deadline-truncated rc-0 job announces
partial outputs there). For `stdout_tail`, re-enter the kernel and read
it from `.result()` after the notification arrives (`call_command` is SSH-only — it bails on a `byoc:`
handle):

```python
# repl tool — cell ① submits and RETURNS
import json
r = json.load(open('built_env.json'))
c = host.compute.create('byoc:modal', provider_params={'modal': {
    'image': r['image'],          # the im-… ref (bare name fallback brittle)
    'env': 'proteomics_gpu',      # bundled-env NAME → its shipped egress declaration applies
    'gpu': 'A100',                # timeout omitted → container gets the Settings default
    'volumes': r['volumes'],
}})
j = c.submit_job(
    intent='load esm2_t6 on GPU',
    command='python -c "from transformers import EsmModel; import torch; '
            'm = EsmModel.from_pretrained(\\"facebook/esm2_t6_8M_UR50D\\").cuda(); '
            'print(torch.cuda.get_device_name())"',
    timeout_seconds=300,          # job guard — this probe finishes in 5 min or it's hung
)
print('JOB_ID:', j.job_id)   # ← cell ends here; kernel never blocks
```

Then exit the cell and use `wait_for_notification`. When the
`compute_done` notification arrives, its payload has `status` /
`exit_code` / `featured_files`, plus `error_kind` / `system_hint` /
`deadline_fired` when set. For `stdout_tail`, re-enter the kernel:

```python
# repl tool — cell ② after the compute_done notification
print(c.attach_job('<JOB_ID>').result()['stdout_tail'])  # non-blocking — poller already harvested
c.close()
```

For a full job with inputs and harvested outputs:

```python
# repl tool — cell ① submits and RETURNS
c = host.compute.create('byoc:modal', provider_params={'modal': {
    'image':   r['image'],               # 'im-…' from build_env(); bare-name fallback exists but is brittle
    'env':     'proteomics_jax_gpu',     # bundled-env NAME → its shipped egress declaration applies
    'gpu':     'A100-40GB',
    'cpu':     8,
    'memory':  32768,                    # MiB — Modal's unit, not GiB
    'volumes': {'/cache': 'af2-params'}, # mount path → Modal Volume name
    'timeout': 3600,                     # container lifetime, seconds — optional; omitted → Settings default; ceiling: Modal's 24 h platform limit
}})
# → tier card → Sandbox.create() under the user's workspace → handle bound to sandbox_id

job = c.submit_job(
    intent='colabfold on target.fasta — 1× A100, ~40 min',
    command='colabfold_batch target.fasta out/ --num-recycle 3 --model-type alphafold2_ptm',
    inputs=[{'src': 'target.fasta', 'dst_filename': 'target.fasta'}],
    outputs=['out/ranked_0.pdb', {'glob': 'out/*.json', 'visibility': 'featured'},
             {'glob': '*.log', 'visibility': 'hidden'}],
    timeout_seconds=2700,                # job guard — optional; default = remaining container life − harvest margin
)
print('JOB_ID:', job.job_id)   # ← cell ends here
```

Then `wait_for_notification` — the `compute_done` payload includes
`featured_files`, so you can `save_artifacts(payload['featured_files'])`
directly without re-entering the kernel. If you want the full dict
(`stdout_tail` / `stderr_tail` / `job_wall_s`):

```python
# repl tool — cell ② after the compute_done notification
r = c.attach_job('<JOB_ID>').result()  # non-blocking read of compute_usage.result
save_artifacts(r['featured_files'])
c.close()
```

`r['job_wall_s']` is the seconds `run.sh` ran on the remote — the actual
GPU/compute duration.

`timeout` is the container's lifetime; `timeout_seconds` guards one job
inside it. Both are optional: `timeout` fills from the Settings default,
`timeout_seconds` from the container's remaining life minus the harvest
margin. Name a `timeout_seconds` when you know the job's budget — a hung
job then costs that budget and the warm container survives. At either
deadline the job is TERMed, given grace, and its outputs are staged and
harvested as on success — the job lands as `status: 'timed_out'`
(deadline-terminated, outputs harvested), not a generic failure.

`inputs=` stage **flat** into the workdir root. `dst_filename` is a bare
filename — `'inputs/gfp.fasta'` is rejected at submit (the file would land
at `/work/gfp.fasta`, not where the command expects). `src` can be a path;
`dst_filename` can't. Omit it to default to `basename(src)`. Need a dir
layout? `mkdir -p` it inside `command=`.

**Sizing `inputs=` — and when to use a Volume instead.** Inputs are
stdin-streamed through a confined path at ~0.65–0.81 MiB/s effective
(measured) — budget staging time from that: 1 GiB ≈ 20–26 minutes of
upload before the job starts, spent from container life. The host
budgets staging from input size with a planning rate it cannot verify
(upload speed isn't controllable), so a slower-than-planned upload never
endangers the harvest — the watchdog's absolute-clock backstop still
protects the staging window; the job just gets less runtime than
nominal. If an upload dies outright, the submit fails LOUDLY with a
transport error and no phantom job. Practical sizing: code, configs, and
small data are what `inputs=` is for; it is workable up to its **1 GiB
per-submit cap** (slow but fine — budget the ~20–26 min of staging near
the cap). Anything above 1 GiB is refused at submit time, so beyond it a
Volume is the only path — and the better one well before that. Volumes
(Files-tab import, or a `compute_provider` cell; mount via
`provider_params.modal.volumes`) persist on Modal disks across jobs and
cost zero upload per submit.

**Checkpoint long jobs as they run.** Write progress to `./out/` (or a
Volume) periodically: at either deadline the workload gets TERM, then a
grace window for checkpoint-on-TERM handlers, and whatever is under
`out/` is staged and harvested unconditionally. A job that checkpoints
loses at most one interval to a deadline — never the run. Keep `./out/`
checkpoints SMALL (≈ ≤100 MB compressed): the harvest stream back to the
host runs in a bounded (~2 min) window, so a multi-GB `./out/` risks
`harvest_failed` even though staging succeeded — large checkpoints
belong on a Volume, with only small summaries under `./out/`.

**Only `./out/` is harvested.** The wrapper tars `out/` + `stdout.log` +
`stderr.log` — nothing else. `outputs=` globs are a *post-harvest* filter
(featured/hidden), not a what-to-collect directive. If your tool
writes to cwd, a Volume mount (e.g. `/atlas`), or `$HOME`, end `command=`
with `cp -r <results> out/` (or point the tool's `-o`/`--output` at `out/`).
A successful job with an empty `out/` returns only the log paths in
`output_files` plus a `system_hint` telling you so.

`command=` is interpolated into a `run.sh` and run via `bash run.sh`.
For anything beyond a single program-with-args — nested quotes, inline
`python -c "…"`, heredocs, pipelines — write the script to a workspace
file and ship it via `inputs=`, then `command='bash script.sh'` or
`command='python script.py'`. Multi-layer shell escaping inside
`command=` is the most common cause of `syntax error near unexpected
token` failures.

`provider_params.modal` uses **Modal's own kwarg names** — Modal's docs are
the docs. The adapter resolves the strings to SDK objects (env name → its
`im-*` from the `compute_details` ledger; volume name → `Volume.from_name`)
and passes the rest through to `Sandbox.create(**params)`. An absent
`timeout` fills from the Settings default before the tier card renders,
so the card shows the real lifetime. A `timeout` above Modal's 24 h
platform cap or out-of-range hardware is rejected with `invalid_request`
before any helper spawns; nothing is silently clamped.

## The image-reference rule

`image` is **always a string**. A `modal.Image` object built in a
`compute_provider` cell cannot cross to the control-plane kernel — they are
separate Python processes under separate confinement invocations, and a live
SDK handle is meaningless on the other side. So the pattern is:

```python
# compute_provider tool — env setup (`modal` and `app` are pre-bound)
img = (modal.Image.from_registry('nvidia/cuda:12.4.1-runtime-ubuntu22.04',
                                 add_python='3.11')
       .pip_install('chai_lab==0.6.1'))
img.build(app)
print(img.object_id)          # → 'im-7f3a2e…' — read this string
```

```python
# repl tool — job
c = host.compute.create('byoc:modal', provider_params={'modal': {
    'image': 'im-7f3a2e…',    # the string, not the object
    ...
}})
```

The adapter validates an `im-*` literal via `Image.from_id()`, which fails
closed on a foreign or fabricated id, so a typo surfaces as `not_found`
before any GPU spins. An env name is looked up in the ledger first
and resolved to the recorded `im-*`; on a miss the adapter returns
`image_build_failed` with copy pointing at
`compute-env-setup` rather than triggering a build inline.

## What latency to expect

Measured against real Modal during validation — set timeouts and user-status
messages from these, not guesses:

| phase | typical | notes |
|---|---|---|
| `Image.from_registry(..., add_python=...).pip_install(...).build(app)` | 130–360s | one-time per `im-*`; runs on Modal's CPU build infra, not your tier |
| `compute.create()` (stateless ctor) | <1ms | just returns a handle — no container, no card |
| first `submit_job()` on a handle, A100 | ~18–30s cold start + job runtime | creates the container (image pull + boot); raises the tier card |
| first `submit_job()` on a handle, H100 | ~20–25s + job runtime | similar; queue wait can add when capacity is tight |
| subsequent `submit_job()` on same handle | ~5–10s + job runtime | reuses the warm container — weights/caches stay hot |

So budget ~3–6 min for a fresh env's first GPU result, and ~5–10s per
subsequent `submit_job()` on the same handle. If a first cold start is
past ~90s, that's queue wait, not a hang — surface it rather than retrying.

## When the user gives you a budget

A user who says "stay under eight GPUs" or "keep it to a hundred at a
time" is giving you a number that the prompt alone can't enforce. You'll
write it into the orchestrator's instructions, but the sub-agents you
delegate to start with fresh context — they never see that line, and
each one will reasonably try to use as much compute as its own task
seems to warrant. Across a wide fan-out that drifts well past whatever
the user had in mind, and the first sign is usually the bill.

`host.compute.set_concurrency_limit(k)` exists so the user's number
becomes a property of the session rather than a sentence in a prompt.
Call it once before delegating; the daemon stores it against the session
root, counts every sub-agent's live job against the same `k`, and
quietly holds any submit that would put the session over (the SDK
retries with backoff under the hood). Sub-agent code is unchanged — the
hold sits below `submit_job`, not in the agent.

Choosing `k` has one constraint beyond the user's intent: each provider
also has its own ceiling, and that ceiling refuses rather than queues.
A session limit above it doesn't fail, it just stops being the binding
constraint — submits past the provider's own ceiling error instead of
waiting. `host.compute.status()` returns both your `k` and the
provider ceilings, so you can pick a value that actually queues. When
the user hasn't given a number, leaving the limit unset keeps today's
behaviour; set one yourself only if a fan-out is wide enough to threaten
the provider cap and you'd rather queue than fail.

## Warm reuse, reattachment, and `close()`

One handle = one container. The first `submit_job()` creates it;
subsequent calls reuse it warm (weights/XLA cache stay hot). The poller's
harvest does **not** terminate the container — it runs until `c.close()`,
~30 min of inactivity (the sandbox's PID-1 **idle watchdog** — a kill,
not a harvest: anything unharvested goes with the container), or its
container timeout, whichever comes first. Until then a finished — or
failed — job's container bills idle. **Every handle ends with
`c.close()`** — after its last job, not between jobs, and not while its
sandbox holds the only copy of unrecovered outputs
(`result_rejected`/`harvest_failed` — see "When the job fails"). Close
once the final `compute_done` has arrived and the harvest is confirmed;
if the next job on this handle is imminent, or the user asked to keep
the container warm across jobs, leave it open and close when the
sequence ends. Near end of life the **harvest watchdog** stops any
running job early enough to stage its outputs, so even the last job
comes back harvested. A warm container is reused only when its
remaining life covers the next job's deadline plus margin; otherwise
the submit transparently
creates a fresh sandbox (one more cold start, same handle) and says so
in a `[note]` line on the submit result.
**Sequential only**: each submit wipes `/work`, so call job N+1's
`submit_job()` after job N's `compute_done` notification arrives; for
parallel jobs use separate handles. A second `create()` with different
`{gpu, cpu, memory}` is a separate container and a separate card. The
detached wrapper survives a Claude Science daemon restart — on restart you'll see
"1 job reattached" rather than a cold start.

**Multiple parallel jobs** (separate handles): submit all in one `repl`
cell, then loop `wait_for_notification` → act on every entry in
`notifications` (several may arrive at once) → repeat until it returns
`{status:'error'}` (= none left). Don't poll `.result()`.

**Before you finish the task**: every handle closed (unless the user
asked to keep one warm, or its sandbox holds unrecovered
`result_rejected`/`harvest_failed` outputs), and no sandbox of yours
still alive in the `compute_provider` kernel
(`modal.Sandbox.list(app_id=app.app_id)` shows what's running). Tear
down job-surface containers with `c.close()`, never a raw
`sb.terminate()` — only `close()` consults the host's
recoverable-outputs gate. Reserve `sb.terminate()` for sandboxes you
created in the kernel, and only ones you recognise from this session —
warm containers from other Claude Science installs share the same app.

## When the job fails

A failed job's container stays up on purpose, so you can fix and
re-submit warm — but "stays up" has a clock on it: the in-sandbox idle
watchdog terminates it after ~30 min of inactivity, and reading files
off it does not reset that clock. If you aren't re-submitting on this
handle now, `c.close()` it and diagnose from the harvested tails and
outputs below — except on `result_rejected` and `harvest_failed`,
where the sandbox holds the only copy of the output; read those
entries before you touch `close()`. For every other kind, closing
loses only what the harvest didn't catch (a core dump, a verbose log,
a `residency:'remote'` output) — and `.download()` can't save it here:
scp is SSH-only and errors on a `byoc:` handle. Read any such file off
the live sandbox from a `compute_provider` cell BEFORE you close: find
it with `modal.Sandbox.list(app_id=app.app_id,
tags={"claude-science-job": "<job_id>"})` — the tag names the job
whose submit cold-started the container: your failed job, unless you
chained submits on a warm handle (each fresh sandbox announces itself
in a `[note]` on its submit result) — then `sb.exec("cat", "<path>")`
to pull the bytes.

Read `r['exit_code']`, `r['stdout_tail']`, and `r['stderr_tail']`. A job
that hit a deadline lands as `status: 'timed_out'` with its partial
outputs already harvested into `hpc/<job_id>/` — check `stdout_tail` for
progress and resubmit with a larger `timeout_seconds` (or resume from a
harvested checkpoint) only if the work was actually cut short. The
errors that come back as `kind` rather than a non-zero exit code map cleanly
onto where to look:

`image_build_failed` — Modal's layer build errored: a yanked PyPI version,
a base-image pull failure, a pin that no longer resolves. The build-log
tail is in the `compute_provider` cell where you ran `build_env()`; fix the
env file and rebuild there. No image reference was produced, so the ledger
stays clean. If you passed an env name to `create()` without ever building
it, the name is valid but no image is in the ledger yet — `build_env()` it
first.

`unauthorized` — token rotated or revoked. The `compute_provider` kernel
will have already exited on the first 401; the next cell respawns and
re-reads `~/.modal.toml`, so the user fixing their token is the whole fix.

`quota_exhausted` — workspace quota, concurrent-GPU limit, or spend cap.
For the concurrent limit, first free what you hold: `c.close()` finished
handles (not one holding unrecovered outputs — see below) and terminate
kernel sandboxes you're done with — idle warm containers count against
it. A spend cap isn't freed by closing — accrued spend stays accrued. If
it still trips, surface the copy verbatim and pause; raising the limit
is the user's billing decision.

`rate_limited` — a request-rate throttle on the token, not capacity:
closing containers frees nothing here. Back off ~60s and stagger
fan-out submissions, per the copy.

`ownership_mismatch` — another install sharing this workspace token adopted
the warm sandbox first. The adapter cold-starts a fresh one; nothing for you
to do beyond noting the banner.

`result_rejected` (`compressed_cap_exceeded`) — output archive larger than
the consented cap. Nothing was written to the workspace and the sandbox is
still warm with `out.tar.gz` intact; the user gets a raise-and-retry
affordance that re-streams without re-running. The sandbox holds the only
copy of the output — do **not** `c.close()` until it's resolved, and
surface it to the user now, not at end of task: the Compute panel lists
the job as recoverable for 24 h, but that listing only blocks
Claude Science-side kills (a queued `close()` is deferred ~15 min, then
executes) — the in-sandbox idle watchdog still terminates the sandbox
after ~30 min of inactivity, only copy included.

`harvest_failed` — the output stream gave up after retries; the warm
sandbox likewise holds the only copy. Same rule: no `c.close()` until
the outputs are recovered — and the recovery path is the user's, not
yours: they retrieve from the recovery list in the Compute panel
(`.download()` errors on a `byoc:` handle, and reuse on it is gated).
Same clocks as above: surface it immediately.

`input_changed` — a submit input was rewritten (or deleted/swapped) between
validation and staging: the transport re-hashes the bytes it actually
uploads and compares them to the sha256 captured at validation time.
Nothing was uploaded and the job never started. Re-run `submit_job()` so
the input is re-validated; if it keeps tripping, something is still writing
that file — wait for the writer to finish before resubmitting.

A plain non-zero `exit_code` with logs is the science tool failing on
inputs — same diagnosis as on SSH.

## What to record

After a successful build, append the `### env:<name>@<spec_sha>` block to
`compute_details` — env-setup.md §"Recording the result" has the snippet.
That ledger is the durable record; don't also write the same facts to
memory. Do NOT record build timings, `validated:` dates, or sha256
confirmations — `spec_sha` already encodes staleness and the rest is
noise. Gotchas you hit (a documented invocation that failed, a flag you
had to add, a quota you bumped into) are worth a free-text line.

## GPU tier reference

| `gpu` value | device | VRAM |
|---|---|---|
| `"A10G"` | NVIDIA A10 | 24 GB |
| `"A100"` | A100-SXM4-40GB | 40 GB |
| `"A100-80GB"` | A100-SXM4-80GB | 80 GB |
| `"H100"` | H100 80GB HBM3 | 80 GB |

Each bundled env carries a `gpu_default` in its `META` — what its author
sized for the typical workload. Start there; reach for a bigger tier when
you have a concrete reason (the model is documented as needing >40 GB, the
last attempt OOM'd), not as a hedge. The approval card shows the tier you
picked, but the grant is keyed on provider only, so once approved for this
conversation a tier change doesn't raise a new card — the user is trusting
your judgment on sizing after the first approval.

## Volumes

Pass `volumes={"/weights": "<vol-name>"}` in `provider_params.modal`. The
mount is a symlink to `/__modal/volumes/<id>/` — always reference it by the
mount path, never the resolved target.

The Files tab lists `byoc:modal` alongside SSH hosts: at `/` it shows
Volumes as top-level directories, and inside one you can browse, import,
and download files (same pane as SSH). The path's first segment is the
Volume's *name*, not a mount path. For scripted listing use a
`compute_provider` cell:
`modal.Volume.from_name('<name>').iterdir('/', recursive=False)`.

## Modal Environment (Settings → Compute → modal → Environment)

Optional, beside the *Default app* setting. A Modal **Environment** is
the workspace namespace apps, images, volumes and sandboxes live in —
with the app, one of the two coordinates every Modal name resolves
under. Claude Science resolves every named object it touches (`App.lookup`,
`Volume.from_name`) in the configured Environment, and the
`compute_provider` kernel is started inside it, so `build_env()` /
`HYDRATE` and an env file's own `modal.Volume.from_name(...)` calls
land there too. Blank — the default — sends no environment at all and
Modal uses its own default (normally `main`, or whatever
`~/.modal.toml` says). You cannot set or change it: it is
host/UI-written (`compute_providers.modal_environment`), never a
`provider_params.modal` field (the schema rejects `environment` /
`environment_name` outright), and the ledger cannot reach it.

### Which Environment and App am I in?

A kernel binds its coordinates at spawn — Environment, app, egress
posture — and never re-reads them, while the user can change the
Settings at any time; a change only reaches what gets created next.
`compute_provider_config()` is how you find out where you actually
stand:

```python
# ── compute_provider tool ──
compute_provider_config()
# → {'provider': 'byoc:modal', 'environment': 'team-bio',
#    'app_name': 'claude-science-default', 'egress_mode': 'allowlist',
#    'config_hash': '93e1a4c20b7f'}

# …and after the user changes the Environment, Default app or Network
# Restrictions mode there, the same call:
# ComputeProviderConfigStale: compute provider config is out of date:
#   this kernel was started with config 93e1a4c20b7f but the provider
#   Settings now hash to 4be09f12aa31. Restart the compute_provider
#   kernel (close it and open a new one) to pick up the new
#   Environment/app/Network Restrictions configuration.
```

Call it before anything expensive. If it returns, trust every value in
the dict (`environment: None` means Modal's workspace default;
`app_name` is already resolved). If it raises, the Settings moved
after this kernel started and there is exactly one remedy: close this
`compute_provider` kernel and open a fresh one, which is born into the
new configuration. `build_env()` makes the same check before building,
so a stale kernel cannot spend twenty minutes on an image in a
namespace the next `submit_job()` — which always follows the live
Settings — will never look at.

Sandboxes follow the same birth rule. A fresh `submit_job()` takes the
Settings of the moment it creates its sandbox; a warm-reuse submit
keeps the Environment, app and egress fence its sandbox was born under
(see *Warm reuse, reattachment, and `close()`*). So a Settings change
— an egress change included — reaches your next fresh sandbox, never a
warm one, and nothing ever moves: images, volumes and running
sandboxes stay where they were created, reachable again the moment the
setting points back.


## Network egress from the job sandbox

What the job container can reach on the network is a per-provider setting
(`Settings → Compute → modal → Network Restrictions`), not something you
choose per submit. The host stamps it onto every new sandbox as Modal's
`outbound_domain_allowlist` (or `block_network`). Four states:

- **Not configured** (`NULL`, the default for new connections and for any
  provider enabled before this setting existed) and **Unrestricted** — the
  sandbox has open internet. The byoc_submit card shows no egress row.
- **Allowlist** — the sandbox may only open outbound connections to a
  list the HOST computes at approval time:
  `(mirror of the user's local sandbox allowlist ∪ a built-in seed of
  pull-only wheel indexes — download.pytorch.org, pypi.nvidia.com — when
  the policy mirrors) ∪ (the policy's extra domains) ∪ (the env's
  declared domains)`. A `mirror:false` policy is never seeded (it is the
  user's explicit "exactly my list"). The card shows the exact final
  list (`Egress limited to N domains`) with each part attributed; only
  portable domain patterns are mirrored (a local bare `*` or interior
  wildcard is dropped and disclosed, never sent to Modal where it means
  something else); and when there is no local allowlist to mirror
  (network isolation off or unavailable) the resolution is unrestricted
  and the card says so. Two hosts are never seeded:
  `storage.googleapis.com` (hydrate the weights volume instead) and the
  write-capable Hugging Face hub/CDNs — an env that pulls from HF at
  job time declares `huggingface.co` + `*.hf.co` itself.
- **No network** — the user chose to create every new job sandbox with
  `block_network`: *all* outbound connections refused. This is a kill
  switch, decided before any allowlist input is even read. The env's
  `egress_domains` / the ledger's `egress:` line are **ignored** under
  it — there is deliberately no channel, yours or an env's, that can
  open a hole in it — and the card says
  "all outbound network is blocked (provider policy: No network)".

You influence exactly one input to that merge: which env declaration
applies. `META["egress_domains"]` is the list of hosts the env's
*documented job-time commands* need (e.g. `api.colabfold.com` for the
default ColabFold MSA server). For a **bundled** env, pass its NAME as
`provider_params.modal.env` (or let the `### env:` ledger block name
it): the host reads the declaration from the SHIPPED file, so it
survives every rebuild and can only select among shipped, reviewed
sets. For an **ad-hoc** env (`build_env(path=…)`), record the `egress:`
ledger line (see `env-setup.md`); that text is agent-written, so the
host re-validates and caps it. Either way it is a **request the user
always sees, never an authority** — it lands on the card as
`(+K declared by this env)`, and a standing "always allow" grant never
skips a card that carries env-declared domains. Declare the exact
job-time hosts only (`HYDRATE` runs in the `compute_provider` kernel,
outside the fence), and you cannot set or widen the policy itself:
`provider_params` rejects `egress_allowlist` /
`outbound_domain_allowlist` outright and `compute_details` cannot reach
the column.

### Skill-driven jobs and the fence

A skill is just commands inside a fenced sandbox: every host its
documented flow dials at job time either rides the merge above or dies
as a connection reset. So declare an env's job-time hosts (its
`META["egress_domains"]` / the ledger's `egress:` line) BEFORE the
first submit, and move big one-time fetches — weights, checkpoints,
sequence databases — out of the job entirely: bake them at image build
or stage them from the `compute_provider` kernel into a Volume, neither
of which is fenced (`env-setup.md` → *"Tool recipes that survive the
egress fence"* has the runnable recipes). *Settings → Compute → modal →
Network Restrictions → Additional domains* is the user-side fallback for
a fetch that truly must happen inside the job.

### Knowing the policy, and reading a network failure

You never have to guess what a job is allowed to reach, because the host
tells you twice — three times when a `compute_provider` kernel is open:
`compute_provider_config()['egress_mode']` there names the mode the
*next* sandbox will be created under, before any submit spends a card.
At submit time the reply carries an `egress` line and
`submit_job` prints it — `[egress] sandbox egress at creation: allowlist
(2 domains; mirror off; +0 from the env)` — and the same string lives on
the handle as `job.egress`. That line describes the sandbox for its whole
life: the policy is captured when the sandbox is created, so what you see
there is what every command in that job runs under, no matter what the
Settings screen says five minutes later. Then, if the job's output ends up
carrying connection-level failures and the sandbox was fenced, the result
and the `compute_done` notification carry a second host-authored line
starting with `[egress]` that names the policy, its size, and the remedy.
Both lines are written by the host from the policy it actually enforced —
they are evidence you can repeat to the user verbatim, not something you
have to infer.

Knowing how a fence fails is what lets you attribute instead of flail.
Modal's allowlist is a TLS/443 SNI filter, so it never answers at the
HTTP layer; everything it refuses dies below that, and each spelling
tells you which rule you hit. These are the shapes we observed live, not
theory:

| what the output says | under an allowlist it means | under No network it means |
|---|---|---|
| `Connection reset by peer` / `ECONNRESET` on an `https://` URL | the host is not on the sandbox's list | (everything already fails earlier, at DNS) |
| `Network is unreachable` / `ENETUNREACH` | the request was not TLS on port 443 — plain `http://`, a non-443 port, or a raw socket — and the filter refuses those even for an *allowed* domain | no route to anything |
| `Temporary failure in name resolution` / `EAI_AGAIN` / `Could not resolve host` | rare under an allowlist (DNS itself is up) | the normal shape: there is no DNS and no network at all |

A `4xx`/`5xx`, on the other hand, means the host *was* reachable and
answered; that is an application problem, not the policy.

The fix depends on the failure class, and the `[egress]` hint names the
suspect host (when the output names one) and the remedy. A host that
simply isn't listed: ask the user to add exactly that name under
*Settings → Compute → modal → Network Restrictions → Additional domains*
(or, for an env's documented commands, declare it in
`META["egress_domains"]`). A non-TLS / non-443 failure (`apt-get`, an
`http://` mirror, a raw socket): no allowlist edit can fix it — use
HTTPS or do that install at image-build time, which is not fenced.
`storage.googleapis.com` during a lazy weights download: hydrate the
env's volume from the `compute_provider` kernel instead of opening the
world's most general bucket host. Under *No network* there is nothing to
add by design. Every policy is read only when a sandbox is **created**,
so resubmit on a **fresh handle** — retrying in (or warm-reusing) the
failed sandbox repeats the failure byte for byte.

Three moves look productive here and are not. Retrying the same command
in the same sandbox cannot succeed, because nothing inside a sandbox can
change its policy. Asking the user to switch to *Unrestricted* because
one domain is missing trades their whole egress posture for a one-line
allowlist edit — name the domain instead. And probing from inside the
job ("let me curl a few sites to test the network") only reproduces the
failure you already have; the `[egress]` line and `job.egress` already
tell you the policy without spending a container on it.

Two Modal-side caveats worth knowing before you debug "the network is
broken": Modal documents `outbound_domain_allowlist` as a **Beta**
feature, and it filters by TLS SNI, so it applies to **TLS on port 443
only** — once an allowlist is set, plain-HTTP and non-443 traffic from
the sandbox is refused regardless of the domain (we verified this live:
`http://example.com` is refused even with `example.com` on the list). A
tool that fetches over `http://` will fail under any allowlist even if
its host is listed; the fix is the tool's HTTPS endpoint, not a wider
allowlist.

## Common env gotchas

These are tool-level quirks, not architecture — things the bundled env files
already handle but that bite when you're writing an ad-hoc env or debugging
a job that should have worked.

- **`Volume.from_name(...)` returns a lazy handle** — `vol.object_id` raises `AttributeError: unhydrated` until the volume is mounted into a `Sandbox.create(volumes={...})`. Don't try to read it; record the volume *name* (that's what `provider_params.modal.volumes` takes anyway).
- **rdkit** (deepchem, molfeat, aizynthfinder): needs `apt_install("libxrender1", "libxext6")` or `rdkit.Chem.Draw` import fails on `libXrender.so.1`. The `chemistry_gpu` env includes these.
- **dgl** CUDA wheels live at `data.dgl.ai`, not PyPI. `envs/proteomics_rfd_diffdock_gpu.py` shows the `find_links=` pattern.
- **DestVI** is `scvi.model.DestVI`, not `scvi.external.DestVI` (moved in scvi-tools ≥1.0).
- Small model weights (esm2_t6_8M, bert-tiny) auto-download to `/root/.cache` on first use — fine for smoke; for repeated jobs hydrate a Volume once.
- **Volume + `TORCH_HOME` path**: torch.hub appends its own `hub/` subdir. If you mount the volume at `/weights` and want torch to find checkpoints there, set `TORCH_HOME=/weights` (torch then reads `/weights/hub/checkpoints/`). Setting `TORCH_HOME=/weights/hub` makes it look at `/weights/hub/hub/` and re-download.
- **molfeat**: use `from molfeat.trans.fp import FPVecTransformer; FPVecTransformer(kind="ecfp:4")(smiles)` — `MoleculeTransformer` raises on default config.
