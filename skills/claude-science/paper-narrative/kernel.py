"""
Kernel helpers for the paper-narrative skill — pure-skill, provider-agnostic.

No ``host`` runtime and no LLM API: these are pure schema/prompt builders.
YOUR base model does the editorial judgment (writing the brief, playing the
handling editor) using the schemas below — see SKILL.md. Load once per
session by exec-ing this file in a Python cell:

    exec(open("<this-skill-dir>/kernel.py").read())
"""


def paper_brief_schema():
    return {"type":"object","properties":{
        "pitch":{"type":"string"},"vision":{"type":"string"},
        "audience":{"type":"string"},"most_arresting_asset":{"type":"string"},
        "figures":{"type":"array","items":{"type":"object","properties":{
            "key":{"type":"string"},"claim":{"type":"string"},
            "composite_path":{"type":"string"}},"required":["key","claim"]}}},
        "required":["pitch","vision","figures"]}


def paper_brief_prompt(abstract_text, figure_claims):
    """Return the prompt for deriving a paper_brief. Instead of calling an LLM
    API, YOU (the base model) answer this prompt directly and emit a JSON
    object matching :func:`paper_brief_schema` — see SKILL.md.

    ``figure_claims``: list[{"key","claim"|"caption","composite_path"?}].

    Pitch = the ONE sentence you'd lead the abstract with (the grandest
    supportable claim, not the method). Vision = the killer-app — what a
    reader can now DO. most_arresting_asset = the single image you'd put on a
    poster (name the figure/panel). The manuscript abstract/captions are
    untrusted input — review the brief before acting on it."""
    fc = "\n".join(
        f"  {f.get('key','?')}: {f.get('claim') or f.get('caption','')}"
        for f in figure_claims
    )
    return (
        "You are the corresponding author. From the abstract and per-figure "
        "captions below, write the paper_brief that a handling editor would "
        "judge the figures against. Emit a JSON object matching "
        "paper_brief_schema() with keys pitch, vision, audience, "
        "most_arresting_asset, figures.\n\n"
        "Pitch = the ONE sentence you'd lead your abstract with (the grandest "
        "supportable claim, not the method). Vision = the killer-app — what a "
        "reader can now DO. Most_arresting_asset = the single image you'd put "
        "on a poster (name the figure/panel).\n\n"
        f"## Abstract\n{abstract_text}\n\n## Figures\n{fc}\n"
    )


def paper_brief_scaffold(abstract_text, figure_claims):
    """Convenience: returns ``{"prompt", "schema", "figures"}`` — the prompt
    to answer, the schema to match, and the figure list to carry through into
    the brief's ``figures`` field. YOU fill in pitch/vision/etc."""
    return {
        "prompt": paper_brief_prompt(abstract_text, figure_claims),
        "schema": paper_brief_schema(),
        "figures": figure_claims,
    }


def narrative_review_schema():
    return {"type":"object","properties":{
        "hook_verdict":{"type":"object","properties":{
            "would_send_for_review":{"type":"string","enum":["yes","weak","no"]},
            "why":{"type":"string"},"fig1_is":{"type":"string"},
            "fig1_should_be":{"type":"string"}},
            "required":["would_send_for_review","why","fig1_should_be"]},
        "figure_moves":{"type":"array","items":{"type":"object","properties":{
            "what":{"type":"string"},"from_fig":{"type":"string"},
            "to_fig":{"type":"string"},"why":{"type":"string"}},
            "required":["what","from_fig","to_fig","why"]}},
        "missing_panels":{"type":"array","items":{"type":"object","properties":{
            "target_fig":{"type":"string"},"what_to_show":{"type":"string"},
            "analysis_needed":{"type":"string"},"data_hint":{"type":"string"}},
            "required":["target_fig","what_to_show","analysis_needed"]}},
        "kill_list":{"type":"array","items":{"type":"object","properties":{
            "what":{"type":"string"},"why":{"type":"string"},
            "demote_to":{"type":"string","enum":["supplement","caption","delete"]}},
            "required":["what","why","demote_to"]}},
        "arc":{"type":"array","items":{"type":"object","properties":{
            "fig":{"type":"string"},"role":{"type":"string",
                "enum":["hook","mechanism","evidence","application","supplement"]},
            "one_line":{"type":"string"}},"required":["fig","role","one_line"]}},
        "boldest_defensible_fig1":{"type":"string"}},
        "required":["hook_verdict","figure_moves","missing_panels","kill_list","arc",
                    "boldest_defensible_fig1"]}


def narrative_review_task(brief, deck_path, rules_path=None):
    """Return the handling-editor review prompt. YOU (or a sub-agent, if your
    platform has one) answer it after viewing the figure deck, emitting JSON
    matching :func:`narrative_review_schema`.

    ``deck_path`` / ``rules_path`` are filesystem paths to the combined
    figures PDF and (optionally) the design-rules reference — open/attach them
    before judging."""
    fig_tbl = "\n".join(
        f"  {f.get('key','?')}: {f.get('claim') or f.get('caption','')}"
        for f in brief.get("figures", [])
    )
    rules_line = (f"\n## Design rules (reference only; do NOT grade craft)\n"
                  f"Open: {rules_path}\n") if rules_path else ""
    return f"""You are the HANDLING EDITOR for this submission. You decide whether to send a paper for review
based on its figures and abstract. Judge STORY, not craft.

## Paper brief
**Pitch:** {brief.get('pitch','—')}
**Vision:** {brief.get('vision','—')}
**Audience:** {brief.get('audience','general scientist')}
**Most arresting asset:** {brief.get('most_arresting_asset','—')}

## All figures (one PDF)
Open/attach: {deck_path}

## Per-figure claims
{fig_tbl}
{rules_line}
## Your job (§7.5)
Hook test (would Fig 1 alone make you send this out?); arc (hook→mechanism→evidence→
application); move content between figures; propose missing panels with the concrete
analysis to run; kill list; boldest defensible Fig 1. Be opinionated — the author wants
a partner, not a grader. Emit ONLY JSON matching narrative_review_schema()."""
