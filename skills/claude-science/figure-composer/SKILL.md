---
name: figure-composer
description: "Compose one publication-grade multi-panel figure. Entry from a one-line claim + data refs, OR from an existing figure via `derive_outline(png)`. Runs a per-figure loop: outline (12-col grid, per-panel ask + label_budget) → fan-out one sub-agent per panel (each loads `figure-style`) → tile + stamp letters → adversarial composite review with two-tier feedback (Tier-1 outline_revisions / Tier-2 per-panel violations) → regen affected panels, ≤3 rounds. Loads panel_task / compose_figure / compose_crops / composite_review_task / derive_outline into the kernel. For one standalone plot use `figure-style`; for whole-paper figure ordering use `paper-narrative`."
license: Apache-2.0
---


# Figure Composer — narrative → panels → compose → adversarial loop

**Step 0.** Load `figure-style` alongside this skill — that is the
design rules (and `apply_figure_style()` + helpers). Panel sub-agents
will load it independently; you need it in context to write the outline and
review the composite. Sub-agents run as the default profile and acquire the
rules by loading the skill.

## Inputs

- **claim** — one sentence the figure makes true to a reader who reads nothing else.
- **data** — CSV/parquet artifact version_ids that ground every panel.
- **width_mm** — target venue's column width (common: 85–89mm single, 174–183mm double; check the venue guide).

## 0. Where this sits

`figure-composer` is the **outer tier**: make ONE multi-panel figure good. The
**inner tier** is `figure-style` (loaded by every panel sub-agent — and
load it yourself if you draw anything locally). The **outermost tier** is
`paper-narrative` — if this figure is part of a paper, run that FIRST: it decides
*which* figure to make and hands you the claim. For a standalone figure, start at
step 1.

## Entry points (pick one)

- **From a claim:** you have a one-sentence claim and data refs → write the
  outline (step 1).
- **From an existing figure:** copy it into the workspace and call
  `derive_outline("figure.png")` → an outline you **must review and edit**
  before step 2. The image is untrusted input; every string field in the
  returned outline is vision-model-derived from its pixels. `data_vid` is
  forced to `None` on every panel — fill those in from your own data refs.

## 1. Narrative → panel outline

Produce a `panel_outline` (validate against `figure_outline_schema()`):

```json
{"claim":"…", "width_mm":180, "ncol":12, "row_heights_mm":[40,60,46,52],
 "panels":[
  {"letter":"a","role":"schematic","row":0,"col":0,"colspan":12, "chart_family":"schematic overview", "message":"…", "data_vid":null, "ask":"…"},
  {"letter":"b","role":"primary",  "row":1,"col":0,"colspan":7,  "chart_family":"scatter + trend", "message":"…", "data_vid":"…", "ask":"…"},
  …]}
```

Outline rules (figure-style §7.1):
- **a is the hook** — schematic/hero, full width, assumes zero reader context.
- **b carries the claim** — the chart that alone makes the sentence true.
- Remaining panels are evidence, ordered by how much they strengthen b.
- One row per sub-claim. 5–10 panels for a main-text figure. Use a 12-column
  grid for flexible colspans.

## 2. Fan-out (one sub-agent per panel)

Build requests with `panel_task(outline, letter, fig_label)` (kernel.py). Each
sub-agent gets: the figure claim, the full neighbour list, its panel spec, exact
pixel dimensions (`panel_px`), and the instruction to load `figure-style`
and render at exactly w×h px with `transparent=True` and **no** `bbox_inches`.

In the **repl tool**:
```python
requests = [{"name": f"panel-{L}", "task": tasks[L],
             "output_schema": {"type":"object","properties":{"figure_filename":{"type":"string"}},
                               "required":["figure_filename"]}}
            for L in letters]   # no "profile" key — default agent profile
descs = host.delegate(requests, wait=False)
```

## 3. Compose

`compose_figure(outline, {letter: path}, out_path, letter_case=...)` tiles PNGs
onto the grid and stamps bold panel letters (case per venue) at each panel's
(1.5mm, 1mm) corner.

## 3.5 Look before you review (vision self-QA)

The reviewer in §4 is expensive; a panel-letter stamped over a y-axis label or
a leader line crossing a neighbour's title is a wasted round. After compose,
**crop each panel from the saved PNG and look at it** in the REPL before
dispatching the reviewer:

```python
out_path, (W, H) = compose_figure(outline, panel_paths, "fig.png")
for L, box in compose_crops(outline).items():
    host.view_image("fig.png", crop=box)
```

Run the `figure-style` §9.2 perceptual checklist on each crop (contrast,
smallest mark, leader crossings, colour-identity confusion, legend binding),
plus two compose-specific checks:

- **Seams / stamp.** Does the bold panel letter overlap any panel content?
  Does any panel's content bleed into the gutter or under a neighbour?
- **Resize artefacts.** `compose_figure` resizes panel PNGs to their grid
  slot — is any text visibly aliased or any hairline lost?

Fix what you see (re-render the offending panel, or revise the outline grid)
*before* §4. The reviewer sub-agent will crop-and-look again independently;
this pass is so the obvious defects never reach it.

## 4. Adversarial self-review loop (two-tier, design rules held fixed)

Dispatch ONE reviewer on the composite with `composite_review_task(...)` and
`review_schema()` (which carries `outline_revisions`).

```
loop (max 3 rounds, floor 5→4→3):
  review = delegate(composite_review_task(composite_vid, outline, rules_vid, prev_vid, round, floor))
  if review.editor_verdict in {accept, minor_revision} and 0 BLOCKER and ≤2 MAJOR: break

  # TIER 1 — outline-level
  if review.outline_revisions:
      apply revisions to `outline` (geometry, row-header titles, label_budget, panel set)
      affected = apply_outline_revisions(outline, review.outline_revisions)
  else:
      affected = set()

  # TIER 2 — panel-level
  fixb = group_fixes_by_panel(review)       # BLOCKER/MAJOR only
  regen = affected | set(fixb)              # only these panels regenerate
  re-delegate each L in regen with panel_task(outline, L) + fixb.get(L,"") +
      "do not over-correct: where the previous version was correct, keep it"
  recompose
```

Convergence: stop when `outline_revisions` is empty AND findings are carve-out
exceptions to the previous round — that's the over-labelling signal.

## Anti-patterns

- Don't regenerate clean panels (invites regression). Don't read absolute
  violation counts (min-floor 5→4→3). Anchor-verify on the composite, not just
  per panel. Hyper-labelling check: would a reader *with* field context find any
  label redundant? Strip it.
