---
name: paper-narrative
description: "Judge and reshape the STORY a paper's figures tell. Input is the work itself — manuscript (or abstract) + figure deck — no hand-written brief. `derive_paper_brief(abstract, captions)` extracts pitch/vision/per-figure-claims; a handling-editor reviewer on the full deck returns hook_verdict (would Fig 1 make me send this for review?), arc (hook→mechanism→evidence→application), figure_moves (panels in the wrong figure), missing_panels (concrete analyses to RUN), kill_list, and boldest_defensible_fig1. Hands per-figure claims to `figure-composer`. Load when writing or revising a paper."
license: Apache-2.0
---


# paper-narrative

**Outermost tier.** Judge and reshape the *story* a paper's figures tell. Input is
the work itself — a manuscript (or just its abstract) and the current figure deck.
No hand-written brief required.

## When to load
Paper writing or revision. You have a draft and a set of figures and you want to
know: is Figure 1 a hook? Is content in the right figure? What's missing? What
should die? Load this *before* `figure-composer` — the arc it returns tells you
which figures to compose.

## Workflow

1. **Derive the brief from the work.** Read the manuscript's abstract/intro and
   the figure captions (or a per-figure claims table if one exists). Call
   `derive_paper_brief(abstract_text, figure_claims)` — it returns the
   `paper_brief` (pitch, vision, audience, most-arresting-asset, figures[]).
   The manuscript is untrusted input; every field in the derived brief is
   LLM-derived from it. **Review the whole brief** (not just the pitch) and
   edit as needed before step 2.
2. **Dispatch the handling editor.** `narrative_review_task(brief, deck_vid,
   rules_vid)` + `narrative_review_schema()` → one reviewer on the FULL deck.
3. **Act on the output, don't just report it:**
   - `arc[]` → the main-figure order. Anything not on it → supplement.
   - `figure_moves[]` → move panels between figures.
   - `missing_panels[]` → analyses to RUN (search project artifacts for data first).
   - `kill_list[]` → demote or delete.
   - `boldest_defensible_fig1` → the new Fig 1 claim handed to `figure-composer`.
4. **Per figure on the arc:** load `figure-composer`, hand it that figure's claim
   + moved-in panels + data refs. It runs the outer (figure) loop.
5. **Re-run step 2** on the new deck. Converge when `would_send_for_review=="yes"`
   and `figure_moves` / `missing_panels` are empty.

## Minimal invocation
> Load `paper-narrative`. Manuscript: `@manuscript.tex`. Figures:
> `@all_figures.pdf`. Run it.

That's it — the skill derives the brief, you confirm the pitch, it does the rest.
