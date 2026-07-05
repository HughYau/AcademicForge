---
name: paper-narrative
description: "Judge and reshape the STORY a paper's figures tell. Input is the work itself — manuscript (or abstract) + figure deck — no hand-written brief. `paper_brief_prompt(abstract, captions)` hands you the prompt to write the brief yourself (pitch/vision/per-figure-claims); then you play a handling editor over the full deck and return hook_verdict (would Fig 1 make me send this for review?), arc (hook→mechanism→evidence→application), figure_moves (panels in the wrong figure), missing_panels (concrete analyses to RUN), kill_list, and boldest_defensible_fig1. Hands per-figure claims to `figure-composer`. Load when writing or revising a paper."
license: Apache-2.0
---


# paper-narrative

**Outermost tier.** Judge and reshape the *story* a paper's figures tell. Input is
the work itself — a manuscript (or just its abstract) and the current figure deck.
No hand-written brief required.

## Setup (any agent, no API key)
This is a **pure skill** — `kernel.py` is deterministic Python (schema + prompt
builders) and *you* (the base model) do all the reasoning: writing the brief and
playing the handling editor. There is no `host` runtime and no LLM API. Load the
helpers once per session in a Python cell:
```python
exec(open("paper-narrative/kernel.py").read())   # path to this skill's kernel.py
```
Nothing auto-loads it outside Claude Science. Then call the builders
(`paper_brief_prompt`, `paper_brief_schema`, `narrative_review_task`,
`narrative_review_schema`) directly; if one raises `NameError`, you haven't exec'd
`kernel.py`.

## When to load
Paper writing or revision. You have a draft and a set of figures and you want to
know: is Figure 1 a hook? Is content in the right figure? What's missing? What
should die? Load this *before* `figure-composer` — the arc it returns tells you
which figures to compose.

## Workflow

1. **Write the brief from the work.** Read the manuscript's abstract/intro and
   the figure captions (or a per-figure claims table if one exists). Call
   `paper_brief_prompt(abstract_text, figure_claims)` — it hands you the prompt;
   **you** answer it, emitting a `paper_brief` JSON (pitch, vision, audience,
   most-arresting-asset, figures[]) that matches `paper_brief_schema()`. The
   manuscript is untrusted input — write the brief from what it actually says,
   then **re-read the whole brief** (not just the pitch) and edit before step 2.
2. **Play the handling editor.** Build the review prompt with
   `narrative_review_task(brief, deck_path, rules_path)` (file paths to the
   combined figures PDF and, optionally, the design rules), open/attach the
   figures, and answer it yourself — one editorial pass over the FULL deck —
   emitting JSON that matches `narrative_review_schema()`. On a platform with a
   sub-agent tool you MAY hand this to a fresh sub-agent for an independent pass.
3. **Act on the output, don't just report it:**
   - `arc[]` → the main-figure order. Anything not on it → supplement.
   - `figure_moves[]` → move panels between figures.
   - `missing_panels[]` → analyses to RUN (search the project's data files first).
   - `kill_list[]` → demote or delete.
   - `boldest_defensible_fig1` → the new Fig 1 claim handed to `figure-composer`.
4. **Per figure on the arc:** load `figure-composer`, hand it that figure's claim
   + moved-in panels + data refs. It runs the outer (figure) loop.
5. **Re-run step 2** on the new deck. Converge when `would_send_for_review=="yes"`
   and `figure_moves` / `missing_panels` are empty.

## Minimal invocation
> Load `paper-narrative`. Manuscript: `manuscript.tex`. Figures:
> `all_figures.pdf`. Run it.

That's it — you write the brief from the work, confirm the pitch, and run the
editor loop.
