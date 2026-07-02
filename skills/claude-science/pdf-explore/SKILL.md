---
name: pdf-explore
description: "Use this skill when the user has attached a PDF, paper, report, or other document and the answer needs content from more than one place in it: summarize the methods or any other section, compare sections, find where a topic is discussed, read a value or label off a figure or chart, or find/list/extract every instance of something across the whole document (datasets, benchmarks, citations, figures, table rows, accession numbers — including appendices). Skip it only for a single lookup of 1–4 pages quoted in your very next response — `read_file(pages=[...])` attaches pages as images that are dropped from context after one turn, so multi-section answers end up re-reading the same ranges repeatedly. Parses the PDF once in the Python kernel: `pdf_pages` (pages as persistent text), `pdf_outline` (TOC), `pdf_scan` (rank pages by relevance), `pdf_map`/`pdf_extract` (per-page summary / structured fields via parallel haiku calls). For PDF creation/manipulation, use reportlab/pypdf directly."
fold_cue: "instead_of=read_file use=pdf_pages/pdf_outline/pdf_scan for multi-page PDF reads — read_file pages drop after one turn"
license: Apache-2.0
---

# PDF Explore — navigate a PDF too big to embed

A 50-page PDF via `read_file` is ~200K tokens in context, and pages
loaded with `read_file(pages=[...])` are dropped from context after one
turn — so multi-section synthesis turns into re-reading the same pages
over and over. And when the answer is "every page" (list all the
datasets / citations / figures / benchmarks mentioned anywhere in this
document), reading the whole thing page-by-page is the expensive way to
get it. This skill parses the PDF once in the Python kernel and runs one
cheap haiku call per page, **in parallel**, so you load only what
matters — or sweep every page without ever putting the pages in your own
context.

## Which helper

| | when | returns |
|---|---|---|
| **`read_file(pages=[...])`** (no skill) | a single lookup of 1–4 pages you will quote in your *very next* response | pages as vision blocks — **dropped from context after one turn** |
| **`pdf_pages(path, pages=[...], mode="text")`** | you need several pages/sections *at the same time* — summaries, comparisons, anything where the answer draws on more than one range | `[{page, text}, ...]` — write to a file then `read_file`; stays in context like any tool output |
| **`pdf_outline(path)`** | structured doc (paper, report, book) | `[{page, heading, level}, ...]` — a TOC |
| **`pdf_scan(path, query, top_k)`** | semantic question, want the K most relevant pages | `{hits: [{page, relevance, summary, text}], n_scanned, usage}` |
| **`pdf_extract(path, schema)`** | **exhaustive list of X across the whole doc** (datasets, citations, figures, table rows, entities) | `[{page, data, usage}, ...]` — then flatten + dedupe |
| **`pdf_map(path, prompt)`** | unstructured doc (transcript, slide dump, compilation), or a free-text question of every page | `{pages: [{page, text}], n_pages, usage}` — every page's answer to `prompt` |
| **`pdf_pages(mode="image", dpi=200)` → `host.view_image(img, crop=…)`** | read a small value, axis label, or legend off a **figure** | a high-res crop of the figure, auto-attached as vision |

Loading this skill auto-injects these into the Python kernel (from
`kernel.py`); call directly, no import. Don't check for or install
`pypdfium2` first — host-managed installs seed it in the default `python`
environment, and if it's genuinely missing the first call raises with an
install recipe (on platform-managed hosts the default env rejects
installs — if the recipe's `manage_packages` call errors, create a domain
env with pypdfium2 **and pillow** and re-run there; pillow does the PNG
encoding for `mode="image"` and is not pulled in by the pypdfium2 wheel).
Go straight to the helper call.

Note: the default backend is pypdfium2 (Google PDFium; permissive
Apache-2.0/BSD-3-Clause). PyMuPDF is honored as a fallback if already
installed, but it is AGPL-3.0-licensed (commercial licenses available from
Artifex): if you embed it in a network-accessible service, AGPL's
source-sharing terms apply to that service.

## Recipe — pull the sections you need as persistent text (synthesis)

For "summarize the methods" / "compare section 3 and section 5" / anything
where the answer draws on several page ranges at once, do **not** read the
ranges one `read_file` call at a time — each call's pages are dropped from
context before you finish, and you will loop re-reading them. Pull **all**
the pages you need in **one** python call, write them to a file, then
`read_file` that:

```python
wanted = [5, 21,22,23,24,25, 62,63,64, 124,125,126]  # from pdf_outline
with open("sections.txt", "w") as f:
    for p in pdf_pages("paper.pdf", pages=wanted, mode="text"):
        f.write(f"\n── page {p['page']} ──\n{p['text']}")
import os; print(f"wrote {os.path.getsize('sections.txt'):,} bytes")
```

Then `read_file(file_path="sections.txt")` — or with `offset=`/`limit=` if
it's over 100KB — and write the answer from that. **Don't `print()` the
page text directly**: any python output over ~16KB is spilled to disk and
you'll be told to `read_file` it anyway, so printing a full chapter costs
two tool calls where writing + reading costs the same two without the
wasted preview. (For a quick look at ≤5 pages, printing is fine.)

~800 tokens/page of text vs ~4,000 tokens/page as vision — and you only pay
it once. Find the page numbers from `pdf_outline` (below) or the paper's
own table of contents first.

## Recipe — navigate by outline (try this first)

```python
for e in pdf_outline("report.pdf"):
    print(f"p{e['page']:>3} {'  ' * (e['level'] - 1)}{e['heading']}")
# → then read_file(file_path="report.pdf", pages=[the section you want])
```

Free and instant when the PDF has an embedded outline (most
LaTeX-compiled papers do). Falls back to a single batched LLM call on
text-layer ≤150pp docs (~$0.001-0.003 total), or per-page LLM heading
extraction on scanned/>150pp (~$0.002/page). For a semantic question the
outline doesn't obviously answer ("where do they discuss
limitations"), fall through to `pdf_scan`.

## Recipe — find the pages relevant to a query

```python
r = pdf_scan("paper.pdf", query="batch-effect correction methods", top_k=5)
for h in r["hits"]:
    print(f"p{h['page']}  {h['relevance']:.2f}  {h['summary'] or h['text'][:100]}")
print(f"[{r['n_scanned']} pages scanned, "
      f"{r['usage']['input_tokens']} in + {r['usage']['output_tokens']} out]")
```

(`summary` is populated only when `strategy="fanout"` — the default
`"auto"` uses single-call comparative ranking on text-mode docs ≤150pp,
which is ~3× cheaper and ranks better but doesn't generate summaries.
Pass `strategy="fanout"` if you want them.)

Then load only those:

```python
# Either: call read_file from the harness (attaches as vision)
#   read_file(file_path="paper.pdf", pages=[h["page"] for h in r["hits"]])
# Or: print the text right here
for h in r["hits"]:
    print(f"\n── page {h['page']} ──\n{h['text'][:2000]}")
# Or: render hit pages to cwd (PNGs auto-attach as vision next turn).
# Fine for layout/skimming — but a full page is too low-res to read
# small values off a figure; for that use the next recipe instead.
for p in pdf_pages("paper.pdf", mode="image",
                   pages=[h["page"] for h in r["hits"]], dpi=150):
    import shutil; shutil.copy(p["image_path"], f"./hit_p{p['page']}.png")
```

`path` can be a workspace path, a `~/`-expanded path, or an artifact
version_id (resolved via `host.artifact_path`).

## Recipe — read a figure in detail

A full rendered page is too low-resolution to read small axis labels,
legend text, or values off a dense multi-panel figure — the attach
pipeline downsamples everything to ≤1568px, so the figure region ends up
at a few hundred pixels no matter what DPI you render at. **Render the
page at high DPI, then crop the figure before attaching.** The crop is
both more legible *and* cheaper (a figure crop is ~400 vision tokens vs
~1,600 for the full page).

```python
# 1. Find the figure's page (pdf_scan on the caption text, or pdf_extract
#    with {"figures": [...]}, or you already know it).
# 2. Render that page at dpi=200 — high enough to crop into. The render
#    lands in .cache/ so it is NOT auto-attached.
p = pdf_pages("paper.pdf", mode="image", pages=[5], dpi=200)[0]
# 3. Attach the full page once to locate the figure, OR go straight to a
#    crop if the caption/position tells you where it is:
host.view_image(p["image_path"], crop=(x0, y0, x1, y1))  # pixels in the dpi=200 render
# → writes the crop to cwd; it auto-attaches at full resolution next turn.
```

Crop to one panel at a time for multi-panel figures. Always crop from
the `.cache/` render, not from a previously attached (downsampled) view.

## Recipe — map every page

For documents with no useful section structure (meeting transcripts,
slide exports, multi-document compilations), get a 2-sentence summary
of every page instead of a ranked subset:

```python
m = pdf_map("transcript.pdf")
for p in m["pages"]:
    print(f"p{p['page']}: {p['text']}")
```

Then pick pages and `read_file(pages=[...])`. 100 pages → ~10K tokens in
context (vs ~400K if you embedded the whole PDF as vision, or ~90K as
extracted text). Nothing is filtered out, so there's no chance the
relevant page was missed. Measured: ~100 output tokens/page.

## Recipe — structured extraction

Pull the same fields from every page in parallel:

```python
rows = pdf_extract("paper.pdf", {
    "type": "object",
    "properties": {
        "figures": {"type": "array", "items": {"type": "object",
            "properties": {"label": {"type": "string"},
                           "caption": {"type": "string"}}}},
    },
    "required": ["figures"],
})
figs = [(r["page"], f) for r in rows for f in (r["data"] or {}).get("figures", [])]
```

**Schemas that work well**: `{figures:[{label,caption}]}` (figure index),
`{citations:[str]}` (bibliography — follow with one `host.llm()` call
to dedupe inline-marker noise), `{section_headings:[str]}` (TOC — this
is what `pdf_outline` does internally), `{gene_symbols:[str]}` (entity
lists), `{rows:[{col1,col2,...}]}` (table rows — whitespace-aligned
tables in the text layer parse cleanly; for rendered/image tables pass
`mode="image"`).

**Put the inclusion criterion in the schema's `description`** — e.g.
`"datasets on which results are actually reported on this page (in a
table or the text), not datasets merely cited or mentioned"`. The
per-page model sees the full page and applies the criterion for you. If
you leave it out you'll end up re-reading pages afterwards to apply it
yourself, which costs more than the sweep did.

**Schemas that don't**: anything requiring judgment about "key" vs "all"
(`{key_claims:[str]}` returns ~10/page, unusable). Per-page extraction
is recall-complete but precision-noisy. For ≲300 raw names, print the
sorted unique names with their page lists and dedupe/normalize them
yourself while writing the final answer — you have the whole list in
context, and a `host.llm` reduce call just hands you back a blob you
then have to parse. Reach for an LLM reduce only above that.

**The sweep already read every page.** Don't follow it with
`read_file(pages=[...])` vision loads to "check for missed items" or to
re-examine specific hits — that re-spends the tokens the sweep just
saved. **Call budget for an exhaustive-extraction job: 2 kernel calls**
— (1) the sweep, printing unique names + page lists; (2) *one* batched
check that prints the cached text of every page you have a doubt about,
collected up front:

```python
doubtful = {"DatasetA", "DatasetB", "DatasetC"}   # decide ALL of them first
pages = sorted({p for n in doubtful for p in name_pages[n]})
for p in pdf_pages("paper.pdf", pages=pages):
    print(f"\n── page {p['page']} ──\n{p['text']}")
```

Then write the answer. The parse is cached so this is instant and free,
the text persists in your context (unlike `read_file` vision pages,
which vanish after one turn), and it's ~5× fewer tokens per page than
an image. If you're about to make a third kernel call to check one more
item, you're doing it wrong — fold it into call 2 or let it go.

## When NOT to use this skill

- **A single lookup of 1–4 pages you will quote immediately**:
  `read_file(file_path=..., pages=[...])` is fine — but only if you write
  your answer on the very next turn, because the attached pages do not
  survive past it.
- **Literal keyword search**: grep the extracted text —
  `[p for p in pdf_pages(path) if "Harmony" in p["text"]]`. `pdf_scan`
  earns its cost on *semantic* queries ("where are the limitations
  discussed") that keywords won't find.

## Mode (scanned PDFs)

All helpers default to `mode="auto"`: try text extraction; if pages
average < 80 extractable characters (scanned document, image-only slide
export), re-parse with page rendering so the LLM sees the image. You
don't need to set this. `"text"`/`"image"` force one or the other.

## Cost & budget

~800 input + 100 output tokens/page in text mode. The sweep helpers in
`kernel.py` pin `PDF_DEFAULT_MODEL = "claude-haiku-4-5"` explicitly on
every request — explicit `model=` wins over the kernel default, so the
sweep is haiku-priced (≈ $0.001–0.003/page depending on page length)
regardless of deployment config. (Ad-hoc `host.llm()` calls you make
yourself are different: bare calls use the Haiku-class kernel default
via `[llm] kernel_default_model` — check `help(host.llm)` if cost
matters there.) Don't
pass a heavier `model=` for extraction; heavier models cost 10-30×
more and add nothing to recall-complete per-page pulls. For a very
large document you can
scan a subset via `pages=range(1, n, 3)`, but stride sampling **can
miss** a narrow relevant span between unrelated neighbors; prefer
`pdf_outline` → read the section you want when the document has
structure.

## Caching

`pdf_pages` caches on `(abs_path, mtime, mode, dpi)` — a second
`pdf_scan`/`pdf_map` with a different `query`/`prompt` on the same file
skips re-parsing and re-rendering. Page renders land in
`./.cache/pdf-explore/{sha8}-{mtime}/dpi{N}/p{NNN}.png` (under
`.cache/` so they do NOT auto-attach — copy ones you want seen to
`./hit_pN.png`).
