---
name: pdf-explore
description: "Use this skill when the user has attached a PDF, paper, report, or other document and the answer needs content from more than one place in it: summarize the methods or any other section, compare sections, find where a topic is discussed, read a value or label off a figure or chart, or find/list/extract every instance of something across the whole document (datasets, benchmarks, citations, figures, table rows, accession numbers — including appendices). Parses the PDF once with a deterministic Python kernel: `pdf_pages` (pages as persistent text, or high-res images), `pdf_outline` (embedded TOC), `pdf_scan` (a lexical pre-filter that narrows a long doc to candidate pages), `pdf_grep` (regex sweep for exhaustive pattern extraction). You read the shortlist and do the relevance / summary / extraction judgment yourself. For PDF creation/manipulation, use reportlab/pypdf directly."
license: Apache-2.0
---

# PDF Explore — navigate a PDF too big to embed

A 50-page PDF read in full is ~200K tokens of context. When the answer
draws on several sections at once (summarize the methods; compare section
3 and section 5), or when the answer is "every page" (list all the
datasets / citations / figures / benchmarks mentioned anywhere in this
document), reading the whole thing page-by-page is the expensive way to
get it. This skill parses the PDF **once** into persistent text with a
deterministic Python kernel, then lets you **narrow** — by outline, by
lexical scan, by regex — and read only the pages you actually need,
reasoning over them yourself. Nothing you read vanishes: it is ordinary
text and ordinary files.

## Setup (any agent, no API key)

This is a **pure skill** — `kernel.py` is deterministic Python and *you*
(the base model) do all the reasoning. There is no `host` runtime and no
LLM API. Load the helpers once per session in a Python cell:

```python
exec(open("skills/claude-science/pdf-explore/kernel.py").read())
# adjust the path to wherever this skill is installed
```

Nothing auto-loads it outside Claude Science. Then call the helpers
directly (no import). If a helper is "not defined", you haven't `exec`'d
`kernel.py` yet — go back and run the line above.

Dependencies: `pip install pypdfium2 pillow` (pillow does the PNG encoding
for `mode="image"`; it is not pulled in by the pypdfium2 wheel).

## Which helper

| | when | returns |
|---|---|---|
| **`pdf_pages(path, pages=[...], mode="text")`** | you need several pages/sections *at the same time* — summaries, comparisons, anything where the answer draws on more than one range | `[{page, text, n_chars}, ...]` — persistent text; write to a file then read it |
| **`pdf_outline(path)`** | structured doc (paper, report, book) with an **embedded** TOC | `[{page, heading, level}, ...]` — the embedded outline, or `[]` if the PDF has none |
| **`pdf_scan(path, query, top_k)`** | narrow a long doc to a handful of candidate pages for a query | `{hits: [{page, score, matched, text}], n_scanned}` — a **lexical pre-filter** (no LLM); *you* read the shortlist and judge relevance |
| **`pdf_grep(path, pattern)`** | **exhaustive** regex sweep (DOIs, accession ids, every "Table N", emails) | `[{page, matches, lines?}, ...]` — every match with its page |
| **`pdf_pages(mode="image", dpi=200)`** | read a small value, axis label, or legend off a **figure** | `[{page, image_path}, ...]` — open the PNG with your agent's image tool |

These come from `kernel.py` — load it via `exec` once per session (see
**Setup**), then call directly. `pdf_resolve(path)` normalizes a path
(a workspace path or a `~/`-expanded path); the helpers call it
internally, so `path` can be either form.

Note: the default backend is pypdfium2 (Google PDFium; permissive
Apache-2.0/BSD-3-Clause). PyMuPDF is honored as a fallback if already
installed, but it is AGPL-3.0-licensed (commercial licenses available from
Artifex): if you embed it in a network-accessible service, AGPL's
source-sharing terms apply to that service.

## Recipe — pull the sections you need as persistent text (synthesis)

For "summarize the methods" / "compare section 3 and section 5" / anything
where the answer draws on several page ranges at once, pull **all** the
pages you need in **one** python call, write them to a file, then read
that file:

```python
wanted = [5, 21,22,23,24,25, 62,63,64, 124,125,126]  # from pdf_outline
with open("sections.txt", "w") as f:
    for p in pdf_pages("paper.pdf", pages=wanted, mode="text"):
        f.write(f"\n── page {p['page']} ──\n{p['text']}")
import os; print(f"wrote {os.path.getsize('sections.txt'):,} bytes")
```

Then read `sections.txt` with your agent's file-read tool (in chunks if
it's large) and write the answer from that. It's ordinary text — one
parse, and you reason over it directly. **Don't `print()` a full chapter**
into the cell output: most agents spill large cell output to disk and make
you re-read it anyway, so writing + reading a file costs the same two steps
without the wasted preview. (For a quick look at ≤5 pages, printing is
fine.)

Text is ~800 tokens/page vs ~4,000 tokens/page as vision, and you pay it
once. Find the page numbers from `pdf_outline` (below) or the paper's own
table of contents first.

## Recipe — navigate by outline (try this first)

```python
for e in pdf_outline("report.pdf"):
    print(f"p{e['page']:>3} {'  ' * (e['level'] - 1)}{e['heading']}")
# → then pull the section you want with pdf_pages(pages=[...])
```

Free and instant when the PDF has an embedded outline (most LaTeX-compiled
papers do). `pdf_outline` reads the **embedded** TOC only — if the PDF has
none it returns `[]`. In that case **build the outline yourself**: pull the
first handful of pages (or a stride sample of a long doc) as text with
`pdf_pages` and pick out the headings by reading them. For a semantic
question the outline doesn't obviously answer ("where do they discuss
limitations"), fall through to `pdf_scan`.

## Recipe — find the pages relevant to a query

`pdf_scan` ranks pages by **lexical** overlap with your query — it is a
cheap **pre-filter**, not a relevance judgment. It narrows a long document
to a handful of candidate pages; *you* then read those pages and decide
which actually answer the question.

```python
r = pdf_scan("paper.pdf", query="batch-effect correction methods", top_k=8)
for h in r["hits"]:
    print(f"p{h['page']}  score={h['score']:.2f}  matched={h['matched']}")
print(f"[{r['n_scanned']} pages scanned]")
```

Then read the shortlist's text and make the final call yourself:

```python
for h in r["hits"]:
    print(f"\n── page {h['page']} ──\n{h['text'][:2000]}")
```

Keep the pages that genuinely address the query; discard lexical false
positives (a page that merely says "batch" in another sense). Because the
ranking is lexical, a synonym the query didn't use won't score — so lean on
your own reading, broaden `top_k` if the shortlist looks thin, and if the
term is one you can spell out, cross-check with `pdf_grep` or `pdf_outline`.

To skim hit pages as images (layout, tables) instead of text, render them
and open the PNGs with your agent's image tool — but a full page is too
low-res to read small values off a figure; for that use the next recipe.

```python
for p in pdf_pages("paper.pdf", mode="image",
                   pages=[h["page"] for h in r["hits"]], dpi=150):
    print(p["image_path"])   # open each with your image tool
```

## Recipe — read a figure in detail

A full rendered page is often too low-resolution to read small axis
labels, legend text, or values off a dense multi-panel figure. **Render
the page at high DPI, then crop the figure region before viewing it** — the
crop is both more legible and cheaper (fewer vision tokens than the whole
page).

```python
# 1. Find the figure's page (pdf_scan on the caption text, pdf_grep on the
#    figure label, pdf_outline, or you already know it).
# 2. Render that page at dpi=200 — high enough to crop into.
p = pdf_pages("paper.pdf", mode="image", pages=[5], dpi=200)[0]

# 3. Open p["image_path"] with your agent's image tool to locate the
#    figure, then crop it yourself with pillow before a close read:
from PIL import Image
Image.open(p["image_path"]).crop((x0, y0, x1, y1)).save("fig_crop.png")
#    (x0,y0,x1,y1) are pixels in the dpi=200 render.
# 4. Open fig_crop.png with your image tool.
```

Crop to one panel at a time for multi-panel figures. Always crop from the
full-resolution render on disk, not from an already-downsampled view.

## Recipe — list / extract every instance of X across the doc

Two shapes, depending on whether X has a pattern.

**Pattern-shaped X** (DOIs, accession numbers, "Figure N", emails,
anything you can write a regex for) → `pdf_grep`, an exhaustive regex sweep
over the parsed text:

```python
hits = pdf_grep("paper.pdf", r"10\.\d{4,9}/[-._;()/:A-Za-z0-9]+")  # DOIs
for h in hits:
    print(f"p{h['page']}: {h['matches']}")
dois = sorted({m for h in hits for m in h["matches"]})
```

Returns `[{page, matches, lines?}]` — every match with its page, so you can
build a page-indexed list. Exhaustive by construction (regex over every
page) and free.

**Judgment-shaped X** (datasets results are *actually reported on*, key
claims, figure captions, table rows) — no regex captures it, so **you read
and extract**. Narrow first if you can (`pdf_outline` to the results
section, or `pdf_scan` / `pdf_grep` on a likely term), then pull those
pages as text and read them:

```python
# e.g. every dataset RESULTS are reported on (not merely cited)
cand = {h["page"] for h in
        pdf_scan("paper.pdf", query="dataset benchmark evaluated", top_k=20)["hits"]}
with open("cand.txt", "w") as f:
    for p in pdf_pages("paper.pdf", pages=sorted(cand)):
        f.write(f"\n── page {p['page']} ──\n{p['text']}")
```

Read `cand.txt` and write the list yourself, applying the inclusion
criterion ("reported on, not merely cited") as you read — that judgment is
now just your own reading. If the document is short, skip the narrowing:
pull **every** page's text into one file and read it straight through —
recall-complete, with no filter that could miss anything. De-dupe and
normalize as you write the final answer — you have the whole candidate list
in context, so collapse "Dataset A" / "DatasetA" / "the A dataset"
yourself.

The parse is cached (see **Caching**), so pulling a few more doubtful pages
in a follow-up call is instant and free. Decide all your doubts up front
and fetch them in one `pdf_pages` call rather than dribbling out
one-page-at-a-time reads.

## When NOT to use this skill

- **A single lookup of 1–4 pages you'll quote immediately**: your agent's
  own PDF/page read tool is fine.
- **Literal keyword / pattern search**: use `pdf_grep`, or filter the
  extracted text directly —
  `[p for p in pdf_pages(path) if "Harmony" in p["text"]]`. `pdf_scan`
  earns its keep on multi-word queries where you want a ranked shortlist to
  read, not on a single exact term.

## Mode (scanned PDFs)

All helpers default to `mode="auto"`: try text extraction; if pages
average < 80 extractable characters (scanned document, image-only slide
export), re-parse with page rendering so you can read the image. You don't
need to set this. `"text"` / `"image"` force one or the other. Note that
`pdf_scan` and `pdf_grep` operate on whatever text layer exists — a
pure-image scan has none, so for those docs render the pages
(`mode="image"`) and read them yourself.

## Cost & budget

Text is ~5× fewer tokens per page than a rendered image and it persists,
so the winning pattern is: parse once, **narrow** (outline → scan → grep),
and read only the pages you land on. For a very large document you can scan
a subset via `pages=range(1, n, 3)`, but stride sampling **can miss** a
narrow relevant span between unrelated neighbors; prefer `pdf_outline` →
read the section you want when the document has structure.

## Caching

`pdf_pages` caches on `(abs_path, mtime, mode, dpi)` — a second `pdf_scan`
/ `pdf_grep` / `pdf_pages` with different arguments on the same file skips
re-parsing and re-rendering. Pass `cache=False` to force a fresh parse.
Page renders land in
`./.cache/pdf-explore/{sha8}-{mtime}/dpi{N}/p{NNN}.png` — copy or point your
image tool at the ones you want to view.
