---
name: remote-compute-ssh
description: Submit→wait_for_notification→harvest workflow for the user's SSH/SLURM hosts. Load once you've decided to dispatch remote.
license: Apache-2.0
---

You've decided to run this on the user's SSH host. This skill covers the
orchestration layer — partitions, env activation, job scripts, file transfer,
recovery — not the science; what to run and why comes from the task and its
own skills. Each `c.submit_job()` puts an approval modal in front of the user
and, once approved, spends their allocation; a string of failed submits costs
their attention, their compute, and their trust. So the shape of a good run
is: read what's already known about this host, ask once for what isn't, land
the first submit, and write down what you learned about the host or compute
provider so the next session goes straight to the job.

## Workflow

Every `host.compute.*` call in this skill runs via the **`repl` tool**
(the control-plane kernel), not the `python` tool. Job submission opens the
user's approval modal and the SSH connection from the orchestrator's own
process; that has to happen outside the sandboxed data workspace, so
`host.compute` simply isn't attached in the `python` tool (you'd see
`host has no method 'compute'`). The two kernels share your workspace
directory but not memory, so the rhythm is: prepare inputs in a `python`
cell (write `./in.dat`, pickle what the job needs), run
`create → submit_job` in a `repl` cell and let the cell return — the
kernel never blocks on compute. Then call the `wait_for_notification`
brain-tool to park until the daemon's poller emits the `compute_done`
notification, and return to the `python` tool to read the harvested
`hpc/<jobId>/` files. The `repl` tool is stdlib-only (`python -I -S`) —
keep pandas/numpy work in the `python` tool and pass data through files.

Start with the `compute_details({provider, mode:'read'})` tool, then bind once:
`c = host.compute.create(provider)`. The doc's shape tells you how much
discovery is left: `### env:` blocks and gotchas mean prior sessions did the
legwork — trust it. A bare `## Resources` header means first contact — spend
one batched `c.call_command('id; module avail 2>&1 | head -40; ls -la ~',
intent=..., login_shell=True)` and one `ask_about_compute` now, before any
submit. The header's `scheduler:` line is detection, not ground truth; `none`
on a thin login node means a heavy direct-exec job would crowd other users, so
when the resources look thin and the details doc has no prior note, ask first.

If the prose doc has a known-working activation, write it directly into your
`command` (e.g. `source <path>/activate && <tool> ...`). If it doesn't, find
one via `c.call_command()` (`module avail X`, `conda env list`, likely app
dirs) or ask. Install only once you've established the tool genuinely isn't
there — user-space (venv/conda under scratch), via `c.call_command()` for a
quick install or as its own `c.submit_job()` if it needs a build node.
Whichever route produced an activation, run the entrypoint once via
`c.call_command()` before building the real job on it.

Then `job = c.submit_job(...)` (see below). `inputs=[{src:'file', dst_filename:
...}]` stages the file for you — there's no `c.upload()` step, and once
submitted there's nothing to verify with `c.call_command('cat ...')`; the job
reads `./<dst_filename>` from its own workdir. End the cell — `submit_job`
returns immediately and the daemon's background poller polls the remote,
harvests everything the job wrote into your workspace under `hpc/<jobId>/`,
and emits a `compute_done` notification when done.

Park on the `wait_for_notification` brain-tool until that notification
arrives. Its payload carries `{job_id, status, exit_code, featured_files,
output_file_count, ...}` — `featured_files` is the subset matching your
featured `outputs:` globs (omitting `outputs:` features everything). Publish
what you want with `save_artifacts(payload['featured_files'])` — that step is
what gives them provenance and surfaces them in the artifact panel. If you
need the full result dict (all `output_files`, `left_on_remote`, etc.),
re-enter a `repl` cell and call `r = c.attach_job(job_id).result()` — a
non-blocking read of what the poller already harvested.
`open(r['output_files'][i])` reads any harvested file directly. Chain a
remote-resident output via
`inputs:[{remote_path: r['left_on_remote'][i]['uri']}]`. Between the
notification and `close()` you can still
`c.download(f"{job.workdir}/<file>")` for anything the harvest missed.
`c.download('/any/absolute/host/path')` works for **any readable file on
the host**, not just job outputs — paths outside scratch/data_roots raise an
approval card the user clicks Allow on. When the user asks you to
fetch a host file, call `c.download()` with the path they gave; the approval
card is the authorization gate, so don't refuse on their behalf and don't
`cp` into scratch first to dodge it. Dotfiles / paths under a dot-directory
(`~/.ssh/*`, `.gitconfig`, `.env`, …) get a hardened per-file confirmation.
`c.close()` once you've confirmed — it cleans up the job workdirs on the
host. Hand back the result verbatim.

## What to record

The `compute_details()` tool is the only state that survives across sessions,
and three of your inputs are the user teaching you how their host works: an
`ask_about_compute` answer, a `User: <text>` redirect from a declined approval
(they clicked Respond and typed what to do instead), or guidance relayed in the
conversation. When one arrives, treat it as a teach loop — read the durable
fact, append it via the `compute_details({mode:'append'})` tool with a
`per user <date>` tag, echo
back what you understood in your next `intent` so the user sees the teaching
landed, then act on it.

Record an activation/partition/account combination you watched succeed too,
tagged with how you know: `verified <date>` if you ran the entrypoint and saw
exit 0, `per user` if from `ask_about_compute`, `untested` if inferred. A
single inline gotcha ("this tool needs `module load cuda/<ver>` here") is worth
keeping; per-job state and transient errors aren't.

When asking, ask once per gap and batch related questions ("Which partition and
account for GPU jobs, and how do I activate `<tool>`?"). Never ask what one
`c.call_command()` would tell you — `module avail` first, then ask for what
only the user knows: their account string, which env they prefer, whether you
may install.

The test for whether something belongs here is whether it is true of the host
or compute provider, or true of the work you ran on it. A preemption limit is
about the provider; a method choice or a result is about the project, and it
will sit in front of every future session on this machine — including
unrelated projects — long after it has stopped being true. The same goes for
what you learn about the user: that belongs in memory, where it is scoped and
correctable. When a session ends and nothing new about the provider came up,
the right amount to write is nothing.

## When the job fails

Read `r['exit_code']` and the harvested log. An infrastructure failure (wrong
partition, env not activated, missing module, OOM, walltime) is yours to fix —
adjust `command`, record the fix, fresh `c.submit_job()`. A tool failure (the science tool ran but errored on inputs)
may be a bad flag or bad input data; one `c.call_command()` to inspect the log
usually says which. Infrastructure-fix retries are cheap on a short smoke test
and expensive on a long allocation, so after two failed submits on the same
job, ask before a third.

If a tool returns `retry_after_user_action: true`, the host itself is
unreachable (key not loaded, VPN, host down) — call `ask_about_compute` with
the error text and wait; don't loop on your own.

## `c.submit_job()` on SSH

`command` is a job script. The host hoists scheduler directives from the top
into the dispatch wrapper, so write them as if you were handing the file to
`sbatch`/`qsub` yourself — one directive per line starting with the scheduler
prefix and a space. The host adds `--job-name`/`--output` bookkeeping (yours
can't override those); GPU/time/partition/account are yours. Don't write
`--array`/`--chdir`/`--wrap` — submit one job per task instead. PBS
(`#PBS -l ...`) and LSF (`#BSUB ...`) follow the same pattern with their
prefix; for `scheduler: none`, omit directives entirely.

The job runs under a login shell, so tools on the host's default
`module`/`conda` PATH are visible — but writing the activation into `command`
is still the reliable path (deterministic, and what gets recorded in the details doc).
The script runs under `bash -eo pipefail`. If you background subprocesses,
`wait` alone returns 0 regardless of their exit codes — capture each pid and
`wait $pid` (or `wait -n` in a loop) so a failing branch surfaces as a non-zero
`exit_code`. `job.cancel()` sends SIGTERM to the process group; a child that
ignores TERM or re-`setsid`s won't be reached, so don't daemonize inside the
script. cwd is a fresh per-job workdir under scratch — inputs stage flat
there as `./<dst_filename>`. `dst_filename` is a bare filename (no `/` —
rejected at submit). Only files under that workdir are harvested; if
your tool takes an `--output-dir`, point it at `./out` or `.`, not an
absolute path under your home or scratch — anything outside the workdir
isn't auto-harvested (pull it afterward with `c.download('/abs/path')`; see
the Workflow section for how the approval gate works).
If the tool insists on a subdir, end the script with a
flatten-to-root step (`cp ./out/*.<ext> ./ 2>/dev/null || true`) so your
`outputs:` globs match, plus an `ls -lh` of the expected files so the log
shows what's there before harvest. The `|| true` matters: under
`-eo pipefail` a missing optional output would otherwise fail the job.
`intent` is the approval-modal headline, the one
line the user reads to decide whether to let this run on their allocation:
name the tool, the target, and the scale; on a retry, say what's different.
`inputs` with `{src}` (workspace-relative path or the literal `{{artifact:ID}}`
marker — not a kernel-resolved `/sessions/...` path) are staged from this
machine; with `{remote_path}` (absolute, under a `data_roots:` entry or
scratch) they're symlinked, no transfer. Anything over ~100 MB that already
lives on the host should be a `{remote_path}`, not a `{src}` — staging is
link-rate and copies into the job workdir. `outputs` — bare string is a featured
deliverable; `{glob, visibility:'hidden'}` is diagnostic;
`{glob, residency:'remote'}` stays on the cluster and comes back as
`left_on_remote`. `harvest:{exclude:['work/**'], max_file_mb, max_total_mb}`
caps what the poller pulls. Harvest likewise caps at ~100 MB per file: larger
outputs stay on the cluster by
default and come back in `left_on_remote` with `reason:'threshold'` — set
`residency:'remote'` to choose that, or `max_file_mb`/`max_total_mb` to tighten
it. A `left_on_remote` URI is for chaining (`inputs:[{remote_path: uri}]`) or
peeking (`c.call_command(f'head -c 4096 {uri_path}', intent=...)`);
`c.download()` it only when you or the user actually need the bytes locally —
it's link-rate-slow and the file is already where the next job needs it.

```python
# repl tool — host.compute isn't attached in the `python` tool
c = host.compute.create('ssh:<cluster>')
job = c.submit_job(
    intent='<tool> on <input> — 1 GPU, ~10 min',
    command='''#SBATCH --gres=gpu:1
#SBATCH --time=15
#SBATCH --partition=<partition>

module load <tool>/<ver>
<tool> ./in.dat --out ./out
cp ./out/*.result ./out/*.json ./ 2>/dev/null || true
ls -lh ./*.result ./*.json''',
    inputs=[
        {'src': 'in.dat', 'dst_filename': 'in.dat'},               # workspace-relative (prepared in a `python` cell)
        {'src': '{{artifact:<id>}}', 'dst_filename': 'ref.dat'},   # artifact marker — either form works
        # or chain a prior job's harvest: {'src': prev_featured[0], 'dst_filename': 'prev.out'}
    ],
    outputs=[
        '*.result',                                                  # featured
        {'glob': '*.json', 'visibility': 'featured'},
        {'glob': '*.log',  'visibility': 'hidden'},
    ],
    timeout_seconds=900,
)
print(job.job_id)   # cell ends here — kernel never blocks on compute
```

Then call the `wait_for_notification` brain-tool. The `compute_done`
notification payload carries `{job_id, status, exit_code, featured_files,
output_file_count, ...}`; act on it directly:

```python
# after wait_for_notification returns the compute_done payload —
# featured_files paths are workspace-relative under hpc/<jobId>/
save_artifacts(payload['featured_files'])   # publish with provenance
```

If you need the fuller result dict (`output_files`, `left_on_remote`,
`remote_workdir`, `stdout_tail`):

```python
# repl tool — non-blocking read of what the poller already harvested
r = c.attach_job(job_id).result()
# r → {status, exit_code, output_files, featured_files, left_on_remote,
#      remote_workdir, ...}
c.close()
```

`output_files` is the complete list (uncapped), ordered featured-first;
the same files are on disk at `hpc/<job_id>/`.

Each `.submit_job()`/`.call_command()` that isn't Always-Allowed shows one
approval modal; max 10 — batch fan-out into one job script, or have the user
click Always-Allow if you're looping.

## When the user gives you a budget

A user who says "stay under twenty nodes" or "keep it to a hundred at a
time" is giving you a number that the prompt alone can't enforce. You'll
write it into the orchestrator's instructions, but the sub-agents you
delegate to start with fresh context — they never see that line, and
each one will reasonably try to use as much compute as its own task
seems to warrant. Across a wide fan-out that drifts well past whatever
the user had in mind, and the first sign is usually the cluster admin's email.

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
constraint — submits past the host's own ceiling error instead of
waiting. `host.compute.status()` returns both your `k` and the
provider ceilings, so you can pick a value that actually queues. When
the user hasn't given a number, leaving the limit unset keeps today's
behaviour; set one yourself only if a fan-out is wide enough to threaten
the host cap and you'd rather queue than fail.

## Submitting several jobs

Submitting a batch and harvesting them as each finishes uses the same
`wait_for_notification` mechanism, just called repeatedly. The poller
tracks every job you submitted, harvests each independently when the
remote reports it terminal, and posts one `compute_done` per job; each
`wait_for_notification` call returns whatever's queued (one or more) and
then blocks for the next.

```python
# repl tool — submit, print ids, end the cell
c = host.compute.create("ssh:gpu-cluster")
jobs = [
    c.submit_job(
        command=f"python fold.py --seed {s} --in input.fasta --out ranked.pdb",
        intent=f"AlphaFold seed {s}",
        inputs=[{"src": "input.fasta", "dst_filename": "input.fasta"}],
        outputs=[{"glob": "*.pdb", "visibility": "featured"}],
        timeout_seconds=3600,
    )
    for s in range(5)
]
print({j.job_id: j.status for j in jobs})
```

Then loop the brain tool. Each call's `notifications` list may contain
more than one entry if two jobs finished while you were processing the
previous batch, so iterate it; the loop ends when the call returns
`{status:'error'}` because no compute jobs remain.

```text
wait_for_notification(timeout_seconds=1800)
→ {status:'received', notifications:[
     {notification_type:'compute_done',
      payload:{job_id:'…', intent:'AlphaFold seed 3', status:'success',
               exit_code:0, featured_files:['hpc/…/ranked.pdb']}}]}
# act on each payload (save_artifacts, or attach_job(jid).result()
# for stdout_tail / full output_files), then:
wait_for_notification(timeout_seconds=1800)
→ {status:'received', notifications:[ …seed 0…, …seed 4… ]}   # two arrived
# act on both, then:
wait_for_notification(timeout_seconds=1800)
→ … repeat until …
→ {status:'error',
   error:'No running children, no pending notifications, no running compute jobs.'}
```

When everything you care about is harvested, call `c.close()` once to
clean up the remote workdirs. Don't put the `create()` in a `with`
block — `__exit__` calls `close()`, which would cancel the still-running
jobs the moment the submit cell ends.

## When the user asks you to set up the host

If the user explicitly asks for help getting a tool or environment running on
this host — *"can you set up boltz here"*, *"install the proteomics stack on
my cluster"*, *"get this box ready for GPU jobs"* — that's
environment-provisioning work, and the `compute-env-setup` skill is the
guide. It walks through the shape of the problem on whatever kind of host
this is (direct conda, Slurm modulefile or `.sif`, container-via-runner,
managed API), the declarative spec for what each env needs, where weights go,
and how to validate that the documented invocation actually works rather than
just that imports succeed. Read `compute_details` first to understand what's
already there and what kind of host you're on, then follow that skill. Treat
it as its own task with its own validation loop — don't fold provisioning
into a job submission.

## When it's unclear what's available on the host

Sometimes `compute_details(provider)` doesn't give clear guidance on which
environment has the package you need, or whether the tool is installed at
all — the doc might be sparse, stale, or just not mention the thing you're
after. Before assuming it's missing, it's fine to probe: send a handful of
quick remote commands (something like `which <tool>`, `conda env list`,
`module avail 2>&1 | grep -i <tool>`, `python3 -c 'import <pkg>'`,
`ls $SCRATCH/images/` — up to ~5 cheap checks) to see if it's already there
under a name the doc didn't capture. If a probe finds it, use it and append
what you learned about the provider to `compute_details` so the next agent
doesn't repeat the search.

If the probes come back empty or ambiguous, that's the point to bring the
user in rather than guess: *"I don't see `<tool>` set up on this host — I
checked conda envs, modules, and the usual paths. I can set it up here
(that's a separate step, a few minutes for a CPU env, longer for GPU +
weights), or if it's somewhere I didn't look, point me at it?"* Setting it
up is environment-provisioning work — see the `compute-env-setup` skill,
which covers building the stack on whatever shape this host is (direct conda,
Slurm modulefile or `.sif`, container-via-runner, managed API), wiring
weight caches, and validating the documented invocation actually works.

Don't improvise installs inline with a job submission; provisioning has its
own validation loop and a half-built env is harder to debug than starting
clean.
