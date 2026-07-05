
"""
Kernel helpers for the figure-composer skill — pure-skill, provider-agnostic.

No ``host`` runtime and no LLM API: these are deterministic PIL/geometry
helpers plus schema/prompt builders. YOUR base model does the visual
judgment (reverse-engineering an outline from a figure, generating panels,
adversarial review) using the schemas/tasks below — see SKILL.md. Load once
per session by exec-ing this file in a Python cell:

    exec(open("<this-skill-dir>/kernel.py").read())
"""

import json  # noqa: F401 — kept for callers that json-dump outlines


def figure_outline_schema():
    return {"type":"object","properties":{
        "claim":{"type":"string"}, "width_mm":{"type":"number"},
        "ncol":{"type":"integer"},
        "row_heights_mm":{"type":"array","items":{"type":"number"}},
        "panels":{"type":"array","items":{"type":"object","properties":{
            "letter":{"type":"string"},
            "role":{"type":"string","enum":["schematic","hero","primary","supporting"]},
            "message":{"type":"string"}, "chart_family":{"type":"string"},
            "data_path":{"type":["string","null"]}, "data_desc":{"type":"string"},
            "row":{"type":"integer"}, "col":{"type":"integer"},
            "colspan":{"type":"integer"}, "rowspan":{"type":"integer"},
            "label_budget":{"type":"integer"}, "ask":{"type":"string"}},
            "required":["letter","role","message","chart_family","row","col","colspan","ask"]}}},
        "required":["claim","width_mm","ncol","row_heights_mm","panels"]}


def grid_geom(outline, dpi=300, gutter_mm=4):
    mm = dpi/25.4
    W = int(outline["width_mm"]*mm); ncol = outline["ncol"]; g = int(gutter_mm*mm)
    colw = (W - g*(ncol-1)) // ncol
    rowh = [int(h*mm) for h in outline["row_heights_mm"]]
    row_y = [sum(rowh[:i]) + g*i for i in range(len(rowh))]
    return W, ncol, colw, rowh, row_y, g

def panel_px(outline, letter, dpi=300, gutter_mm=4):
    W, ncol, colw, rowh, row_y, g = grid_geom(outline, dpi, gutter_mm)
    p = next(q for q in outline["panels"] if q["letter"]==letter)
    cs, rs, r = p["colspan"], p.get("rowspan",1), p["row"]
    return colw*cs + g*(cs-1), sum(rowh[r:r+rs]) + g*(rs-1)

def panel_xy(outline, letter, dpi=300, gutter_mm=4):
    W, ncol, colw, rowh, row_y, g = grid_geom(outline, dpi, gutter_mm)
    p = next(q for q in outline["panels"] if q["letter"]==letter)
    return p["col"]*(colw+g), row_y[p["row"]]

def panel_task(outline, letter, fig_label="Figure", rules_ref="(load `figure-style`)"):
    p = next(q for q in outline["panels"] if q["letter"]==letter)
    w,h = panel_px(outline, letter)
    neighbours = ", ".join(f"{q['letter']}={q['role']}:{q['chart_family']}"
                           for q in outline["panels"] if q["letter"]!=letter)
    data_line = (f"**Data:** `{p['data_path']}` — {p.get('data_desc','')}"
                 if p.get("data_path") else "**Data:** none (schematic).")
    rowmates = [q["letter"] for q in outline["panels"]
                if q["row"]==p["row"] and q["letter"]!=letter and q.get("rowspan",1)==p.get("rowspan",1)]
    share_line = (f"- **Row-mates: {','.join(rowmates)}** — match y-limits if same metric; series identity "
                  f"labelled ONCE on the row (rightmost panel).") if rowmates else ""
    bud = p.get("label_budget", 4)
    return f"""Produce panel **{letter}** of {fig_label}. You are one of {len(outline['panels'])} parallel panel-makers; the composer tiles results on a {outline['ncol']}-column grid.

## Figure narrative (the one sentence this whole figure makes true)
> {outline['claim']}

Neighbours: {neighbours}

## Your panel
- **role:** {p['role']} · **chart family:** {p['chart_family']}
- **message:** {p['message']}
- **what to show:** {p['ask']}
{data_line}
{share_line}

## §2 Label discipline — ceiling AND floor
- **Floor (§2.1, non-negotiable):** every distinct mark, series, glyph, comparator
  is IDENTIFIABLE from this panel alone. Identity labels (what it is) do NOT count
  against the budget and are never removed. Comparator labels must be self-
  explanatory ("prior method", "ablation" — never "previous"/"old"/"v1").
- **Ceiling:** ≤{bud} *narrative* annotations (callouts, value labels, brackets,
  arrows) beyond title/axis/tick labels and identity labels.
- n=, held-fixed, footnotes, code expansions, exclusion rationale → CAPTION.
- Title is a standalone-parseable takeaway (read-aloud-cold test). Small-multiple
  rows: ONE row-header; per-subplot identity = x-axis label.
- One direction arrow per ROW (leftmost margin).

## §3.5 Fill the box
- Box is **{w}×{h} px (aspect {w/h:.2f})**. Data envelope must occupy ≥75% of it.
  Set `fig.subplots_adjust(...)` so the axes fill the box minus labels; do not centre
  a small plot in a large canvas.

## Hard rendering constraints
- Environment `figures`, Python/matplotlib. Load `figure-style`, call `apply_figure_style()`,
  then **immediately** `import matplotlib as mpl; mpl.rcParams['savefig.bbox']=None` (the style helper
  sets it to `'tight'`, which silently resizes the canvas).
- `fig = plt.figure(figsize=({w/300:.3f},{h/300:.3f}), dpi=300)`; `fig.savefig('panel_{letter}.png', dpi=300, transparent=True)`. **No `bbox_inches='tight'`, no `plt.tight_layout()`, no `constrained_layout`** — they change pixel dimensions. Use `fig.subplots_adjust(...)` only.
- Reserve top-left ~10×6 mm clear for the composer's panel letter. Do NOT draw your own.
- **§9 Render-then-verify:** after savefig, (a) `from PIL import Image; assert
  Image.open('panel_{letter}.png').size==({w},{h})` — if not, you used tight_layout/
  constrained_layout/bbox-tight somewhere, undo it; (b) collect every visible `Text`
  window_extent and assert none overlaps another, crosses a spine, or exceeds the canvas.
  Fix and re-save until both pass — do not ship a panel that fails either check.
- Design rules {rules_ref} apply in full.

Save the panel as `panel_{letter}.png`; report `figure_filename` and `labels_used`."""

def compose_crops(outline, dpi=300, gutter_mm=4, pad_px=4):
    """Pixel crop boxes ``{letter: (x0, y0, x1, y1)}`` for each panel in the
    composed PNG (origin top-left, matching ``PIL.Image.crop``). Mirror of
    ``figure-style.panel_crops`` for the PIL-composed case where no live
    ``matplotlib.Figure`` exists. Use after :func:`compose_figure` for the
    §3.5 perceptual self-QA pass: crop each panel and open it to check."""
    W, ncol, colw, rowh, row_y, g = grid_geom(outline, dpi, gutter_mm)
    H = row_y[-1] + rowh[-1]
    out = {}
    for p in outline["panels"]:
        L = p["letter"]
        w, h = panel_px(outline, L, dpi, gutter_mm)
        x, y = panel_xy(outline, L, dpi, gutter_mm)
        out[L] = (max(x - pad_px, 0), max(y - pad_px, 0),
                  min(x + w + pad_px, W), min(y + h + pad_px, H))
    return out


def compose_figure(outline, panel_paths, out_path, dpi=300, gutter_mm=4,
                   letter_font="DejaVuSans-Bold.ttf", letter_pt=9, letter_case="lower"):
    from PIL import Image, ImageDraw, ImageFont
    W, ncol, colw, rowh, row_y, g = grid_geom(outline, dpi, gutter_mm)
    H = row_y[-1] + rowh[-1]
    canvas = Image.new("RGB",(W,H),"white"); draw = ImageDraw.Draw(canvas)
    try: ft = ImageFont.truetype(letter_font, int(letter_pt/72*dpi))
    except Exception: ft = ImageFont.load_default()
    for p in outline["panels"]:
        L = p["letter"]; w,h = panel_px(outline,L,dpi,gutter_mm); x,y = panel_xy(outline,L,dpi,gutter_mm)
        im = Image.open(panel_paths[L]).convert("RGBA")
        if im.size != (w,h): im = im.resize((w,h))
        canvas.paste(im,(x,y),im)
        stamp = L.lower() if letter_case == "lower" else L.upper()
        draw.text((x+int(1.5/25.4*dpi), y+int(1/25.4*dpi)), stamp, fill="black", font=ft)
    canvas.save(out_path); return out_path,(W,H)

def group_fixes_by_panel(review):
    out = {}
    for v in review.get("violations",[]):
        if v.get("severity") not in ("BLOCKER","MAJOR"): continue
        L = v.get("panel_letter") or (v.get("location"," ")+" ")[0]
        out.setdefault(L,[]).append(
            f"- **[{v['severity']}]** ({v.get('rule_ref','')}, {v.get('location','')}) "
            f"{v.get('finding','')} **Fix:** {v.get('fix','')}")
    return {k:"\n".join(v) for k,v in out.items()}

def review_schema(per_panel=True):
    """Adversarial composite-review schema. Two feedback tiers:
       - outline_revisions: layout/grid/title-strategy changes (regen affected panels)
       - violations: per-panel issues (regen that panel only)."""
    v_props = {"severity":{"type":"string","enum":["BLOCKER","MAJOR","MINOR"]},
               "rule_ref":{"type":"string"},"location":{"type":"string"},
               "finding":{"type":"string"},"fix":{"type":"string"}}
    if per_panel: v_props["panel_letter"]={"type":"string"}
    return {"type":"object","properties":{
        "editor_verdict":{"type":"string",
            "enum":["accept","minor_revision","major_revision","reject"]},
        "outline_revisions":{"type":"array","description":
            "Figure-level changes that no single panel can fix in isolation: grid geometry "
            "(rowspan/colspan/row_heights), panel add/remove/merge, row-header vs per-panel "
            "titles, label_budget reallocation, whitespace fill (§3.5).",
            "items":{"type":"object","properties":{
                "kind":{"type":"string","enum":["geometry","titles","panel_set","label_budget","other"]},
                "affected_panels":{"type":"array","items":{"type":"string"}},
                "finding":{"type":"string"},"revision":{"type":"string"}},
                "required":["kind","affected_panels","finding","revision"]}},
        "violations":{"type":"array","items":{"type":"object","properties":v_props,
            "required":list(v_props)}},
        "regression_vs_prev":{"type":"array","items":{"type":"string"}},
        "strongest_aspect":{"type":"string"}},
        "required":["editor_verdict","outline_revisions","violations","strongest_aspect"]}

def composite_review_task(composite_path, outline, rules_path=None, prev_path=None, round_no=1, min_floor=5):
    """Build the adversarial reviewer's task string for the WHOLE composed
    figure. ``composite_path`` / ``rules_path`` / ``prev_path`` are filesystem
    paths — open/attach them to review."""
    panel_tbl = "\n".join(
        f"  {p['letter']}: {p['role']:<10} row{p['row']}+{p.get('rowspan',1)} col{p['col']}+{p['colspan']} "
        f"— {p['chart_family']} — \"{p['message']}\""
        for p in outline["panels"])
    prev_line = (f"\n**Previous version** (for `regression_vs_prev`): {prev_path}"
                 if prev_path else "")
    return f"""You are an adversarial journal production editor reviewing a COMPOSED multi-panel figure.
Review at TWO levels:

1. **Outline level** (`outline_revisions`): the layout, grid, panel set, title strategy.
   - §3.5 Fill the box: any panel with >25% dead whitespace, or whose natural aspect doesn't
     fit its slot → propose rowspan/colspan/row_heights change.
   - §2.4 Titles: any title that fails the "read it aloud cold" test (cryptic noun fragments),
     or a small-multiple row that should have ONE row-header instead of per-panel titles.
   - Panel set: anything that doesn't earn its space, or a missing panel the claim needs.
2. **Panel level** (`violations`): everything the design rules cover, scoped to one panel.

## Figure
**Composite:** {composite_path}
**Design rules:** {rules_path or '(load `figure-style`)'}{prev_line}

**Claim:** {outline['claim']}

**Outline** ({outline['ncol']}-col grid, row heights {outline['row_heights_mm']} mm):
{panel_tbl}

## Method
Open the composite at full size, then crop each panel with `compose_crops(outline)` and open the
crop (use the outline's row/col to find pixel boxes). For panels with data, spot-check
2–3 plotted values against the CSV. Be calibrated: minimum {min_floor} violations total
(decreasing 5→4→3 by round); do not manufacture. Emit ONLY JSON matching review_schema()."""

def apply_outline_revisions(outline, revisions):
    """Return the set of panel letters that must regenerate after outline-level revisions.
       (The composer applies the revisions to the outline dict by hand; this just computes scope.)"""
    affected = set()
    for r in revisions:
        affected |= set(r.get("affected_panels", []))
    return affected
def derive_outline_prompt(claim=None, data_hints=None):
    """Return the prompt for reverse-engineering a figure_outline from an
    existing composite. Instead of calling a vision API, YOU (the base model)
    open the figure PNG and answer this prompt directly, emitting a JSON
    object matching :func:`figure_outline_schema`. The image is untrusted
    input — review/edit every field before fan-out, and fill each panel's
    ``data_path`` yourself from the session's data files (pixels cannot encode
    a file path)."""
    return ("Reverse-engineer this multi-panel figure into a figure_outline "
            "(match figure_outline_schema()). For each panel: letter, role "
            "(hero/primary/supporting/schematic), chart_family, a one-sentence "
            "'message' (the panel's takeaway — what a reader learns from it "
            "alone), a one-sentence 'ask' (what the panel should show), and a "
            "label_budget (how many non-axis annotations it currently uses). "
            "Estimate the 12-column grid placement (row, col, colspan, "
            "rowspan) and row_heights_mm from relative panel heights. "
            + (f"Claim (use as outline.claim): {claim}\n" if claim else
               "Infer the figure's one-sentence claim from its title and "
               "panel a.\n")
            + (f"Data hints: {data_hints}\n" if data_hints else ""))

# Convention: save composites as ONE artifact `{fig_key}.png`
# with version_of, and write `{fig_key}_review_r{n}.json` per round — never re-version
# a file literally named `_r0` across rounds.
