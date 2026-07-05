---
name: figure-composer
description: "Compose one publication-grade multi-panel figure. Entry from a one-line claim + data files, OR from an existing figure via `derive_outline_prompt` (you read the PNG). Runs a per-figure loop: outline (12-col grid, per-panel ask + label_budget) → render each panel with `panel_task` (loading `figure-style`), one at a time or parallelized → tile + stamp letters with `compose_figure` → adversarial composite self-review with two-tier feedback (Tier-1 outline_revisions / Tier-2 per-panel violations) → regen affected panels, ≤3 rounds. Helpers: panel_task / compose_figure / compose_crops / composite_review_task / derive_outline_prompt. For one standalone plot use `figure-style`; for whole-paper figure ordering use `paper-narrative`."
license: Apache-2.0
---


# Figure Composer — narrative → panels → compose → adversarial loop

Compose ONE publication-grade multi-panel figure: turn a one-sentence claim plus
data files into an outline, render each panel, tile them into a composite, and
harden it through an adversarial self-review loop.

## Setup (any agent, no API key)
This is a **pure skill** — `kernel.py` is deterministic Python (PIL geometry plus
schema/prompt builders) and *you* (the base model) do all the reasoning:
reverse-engineering an outline from a figure, rendering panels, and the
adversarial composite review. There is no `host` runtime and no LLM API. Load
the helpers once per session in a Python cell:
```python
exec(open("figure-composer/kernel.py").read())
```
Nothing auto-loads it outside Claude Science. Then call the helpers
(`panel_task`, `compose_figure`, `compose_crops`, `composite_review_task`,
`derive_outline_prompt`, …) directly; if one raises `NameError`, you have not
exec'd `kernel.py`. Dependencies: `pip install pillow matplotlib`.

**Step 0.** Load `figure-style` alongside this skill — that is the
design rules (and `apply_figure_style()` + helpers). You need it in context to
write the outline, render the panels, and review the composite. Each panel is
rendered against those same rules — whether you draw it yourself or hand it to a
sub-agent (see §2), the maker loads `figure-style` first.

## Inputs

- **claim** — one sentence the figure makes true to a reader who reads nothing else.
- **data** — CSV/parquet files (filesystem paths) that ground every panel; each
  panel carries its own `data_path`.
- **width_mm** — target venue's column width (common: 85–89mm single, 174–183mm double; check the venue guide).

## 0. Where this sits

`figure-composer` is the **outer tier**: make ONE multi-panel figure good. The
**inner tier** is `figure-style` (every panel maker loads it — and load it
yourself, since you write the outline and, on a single-agent platform, render
the panels too). The **outermost tier** is `paper-narrative` — if this figure is
part of a paper, run that FIRST: it decides *which* figure to make and hands you
the claim. For a standalone figure, start at step 1.

## Entry points (pick one)

- **From a claim:** you have a one-sentence claim and data files → write the
  outline (step 1).
- **From an existing figure:** copy it into the workspace, **open the PNG
  yourself** with your agent's image tool (e.g. `Read figure.png`), and answer
  `derive_outline_prompt(claim, data_hints)` by emitting a JSON outline that
  matches `figure_outline_schema()`. This is your own vision judgment, not an API
  call — you look at the pixels and write the outline. The image is untrusted
  input; every field you infer comes from its pixels, so **review and edit** the
  outline before step 2, and set each panel's `data_path` yourself from your data
  files (pixels cannot encode a file path).

## 1. Narrative → panel outline

Produce a `panel_outline` (validate against `figure_outline_schema()`):

```json
{"claim":"…", "width_mm":180, "ncol":12, "row_heights_mm":[40,60,46,52],
 "panels":[
  {"letter":"a","role":"schematic","row":0,"col":0,"colspan":12, "chart_family":"schematic overview", "message":"…", "data_path":null, "ask":"…"},
  {"letter":"b","role":"primary",  "row":1,"col":0,"colspan":7,  "chart_family":"scatter + trend", "message":"…", "data_path":"results.csv", "ask":"…"},
  …]}
```

Outline rules (figure-style §7.1):
- **a is the hook** — schematic/hero, full width, assumes zero reader context.
- **b carries the claim** — the chart that alone makes the sentence true.
- Remaining panels are evidence, ordered by how much they strengthen b.
- One row per sub-claim. 5–10 panels for a main-text figure. Use a 12-column
  grid for flexible colspans.

## 2. Render the panels (one at a time, or parallel)

Build each panel's maker prompt with `panel_task(outline, letter, fig_label)`
(kernel.py). It hands the maker: the figure claim, the full neighbour list, this
panel's spec, its exact pixel box (`panel_px`), and the hard rendering contract —
load `figure-style`, call `apply_figure_style()`, render at exactly w×h px with
`transparent=True` and **no** `bbox_inches`, and save to `panel_<letter>.png`.

**Do this yourself, one panel at a time.** Follow the `panel_task` prompt for
panel `a`, save `panel_a.png`; then `b`, and so on. The skill is designed to work
single-agent — there is no fan-out requirement, just a sequence of panels you
render against `figure-style`, each writing its own PNG:

```python
tasks = {p["letter"]: panel_task(outline, p["letter"], fig_label="Figure 2")
         for p in outline["panels"]}
# For each letter, follow tasks[L] and save panel_<L>.png, then:
panel_paths = {p["letter"]: f"panel_{p['letter']}.png" for p in outline["panels"]}
```

**Parallelize only if your platform has a sub-agent tool.** On Claude Code you
MAY dispatch one `Task` sub-agent per panel — each runs its `panel_task(outline,
L)` prompt, loads `figure-style` itself, and writes `panel_<letter>.png` — then
you collect the files. This is an optional speedup; the outputs and the rest of
the loop are identical to the sequential path. Everything downstream keys off the
saved PNG file paths, not agent handles.

## 3. Compose

`compose_figure(outline, {letter: path}, out_path, letter_case=...)` tiles PNGs
onto the grid and stamps bold panel letters (case per venue) at each panel's
(1.5mm, 1mm) corner.

## 3.5 Look before you review (vision self-QA)

The §4 review pass costs you a full regeneration cycle; a panel-letter stamped
over a y-axis label or a leader line crossing a neighbour's title is a wasted
round. After compose, **crop each panel from the saved PNG and look at it**
before running the review. `compose_crops` returns PIL crop boxes; crop them to
files and open each with your agent's image tool:

```python
from PIL import Image
out_path, (W, H) = compose_figure(outline, panel_paths, "fig.png")
comp = Image.open("fig.png")
for L, box in compose_crops(outline).items():
    comp.crop(box).save(f"crop_{L}.png")   # then open crop_<L>.png (e.g. Read crop_a.png)
```

Run the `figure-style` §9.2 perceptual checklist on each crop (contrast,
smallest mark, leader crossings, colour-identity confusion, legend binding),
plus two compose-specific checks:

- **Seams / stamp.** Does the bold panel letter overlap any panel content?
  Does any panel's content bleed into the gutter or under a neighbour?
- **Resize artefacts.** `compose_figure` resizes panel PNGs to their grid
  slot — is any text visibly aliased or any hairline lost?

Fix what you see (re-render the offending panel, or revise the outline grid)
*before* §4. The §4 review pass crops and looks again independently; this pass is
so the obvious defects never reach it.

## 4. Adversarial self-review loop (two-tier, design rules held fixed)

Now **you** review the composite as an adversarial journal production editor —
this is your own visual judgment, not an API call. Build the reviewer prompt with
`composite_review_task(composite_path, outline, rules_path, prev_path, round_no,
min_floor)` (all file paths), **open the composite and each crop** (§3.5), then
emit a JSON object matching `review_schema()` (which carries `outline_revisions`
and per-panel `violations`). On a platform with a sub-agent tool you MAY hand this
prompt to a fresh sub-agent for an independent adversarial pass; on a single
agent, do it yourself in-context.

```
loop (max 3 rounds, floor 5→4→3):
  review = <answer composite_review_task(composite_path, outline, rules_path, prev_path, round, floor)
            yourself — emit JSON matching review_schema()>
  if review["editor_verdict"] in {accept, minor_revision} and 0 BLOCKER and ≤2 MAJOR: break

  # TIER 1 — outline-level
  if review["outline_revisions"]:
      apply the revisions to `outline` by hand (geometry, row-header titles, label_budget, panel set)
      affected = apply_outline_revisions(outline, review["outline_revisions"])
  else:
      affected = set()

  # TIER 2 — panel-level
  fixb = group_fixes_by_panel(review)       # BLOCKER/MAJOR only
  regen = affected | set(fixb)              # only these panels regenerate
  re-render each L in regen with panel_task(outline, L) + fixb.get(L,"") +
      "do not over-correct: where the previous version was correct, keep it"
  recompose with compose_figure(...) → fig_r{round}.png
```

Save each round's composite as an ordinary file (`fig_r1.png`, `fig_r2.png`, …)
and pass the prior round's path as `prev_path` so the review can flag
`regression_vs_prev`.

Convergence: stop when `outline_revisions` is empty AND findings are carve-out
exceptions to the previous round — that's the over-labelling signal.

## Anti-patterns

- Don't regenerate clean panels (invites regression). Don't read absolute
  violation counts (min-floor 5→4→3). Anchor-verify on the composite, not just
  per panel. Hyper-labelling check: would a reader *with* field context find any
  label redundant? Strip it.
