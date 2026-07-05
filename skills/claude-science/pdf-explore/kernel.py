"""
Kernel helpers for the pdf-explore skill — pure-skill, provider-agnostic.

There is no ``host`` runtime and no LLM API here: the helpers below are
deterministic Python that parse a PDF once into persistent text/images. YOUR
base model (whatever agent you are running) does the reading, ranking, and
extraction over that material — see SKILL.md. This is what makes the skill
work identically on Claude Code, Codex, OpenCode, or any other agent, with no
API key and no configuration.

Load once per session by exec-ing this file in a Python cell (nothing
auto-injects it outside Claude Science):

    exec(open("<this-skill-dir>/kernel.py").read())

then call the helpers directly. All names are ``pdf_``-prefixed. Non-stdlib
imports are inside function bodies so the module loads in a bare environment.

Surface:
    pdf_pages(path, ...)      — parse → [{page, text, n_chars, image_path?}]
    pdf_outline(path)         — embedded table of contents ([] if none)
    pdf_scan(path, query)     — lexical relevance pre-filter → candidate pages
    pdf_grep(path, pattern)   — regex sweep across the whole document
    pdf_resolve(path)         — expand ~ / validate a filesystem path
"""

import hashlib
import os
import re


PDF_PAGE_CACHE = {}
"""(abs_path, mtime, mode, dpi) → [{page, text, n_chars, image_path?}].

Module-level so repeat calls on the same file with a different query skip
re-parsing/re-rendering. Cleared only on kernel restart."""


PDF_AUTO_IMAGE_CHARS_THRESHOLD = 80
"""Mean chars/page below which ``mode='auto'`` switches text→image.
Rasterized scans and image-only slide-deck exports land at 0; real
text-layer PDFs are typically 1000+ even on sparse pages."""


def pdf_resolve(path_or_vid):
    """Expand/validate a filesystem path (``~`` is expanded).

    Artifact/version ids are a Claude Science concept with no local store
    here — pass a real path to the PDF instead of an id.
    """
    if not isinstance(path_or_vid, str) or not path_or_vid:
        raise TypeError("pdf_resolve: path must be a non-empty str")
    p = os.path.expanduser(path_or_vid)
    if os.path.exists(p):
        return p
    # An 8-4-4-4-12 hex id looks like an artifact/version id — there is no
    # artifact store outside Claude Science.
    if re.fullmatch(r"[0-9a-fA-F-]{32,36}", path_or_vid.strip()):
        raise FileNotFoundError(
            f"pdf_resolve: {path_or_vid!r} looks like an artifact/version id, "
            f"which has no local store outside Claude Science. Pass a "
            f"filesystem path to the PDF instead."
        )
    return p


def pdf_pages(path, mode="auto", pages=None, dpi=100, cache=True):
    """Parse a PDF into a per-page list. Cached on (path, mtime, mode, dpi).

    Returns ``[{"page": 1-indexed int, "text": str, "n_chars": int,
    "image_path": str|None}, ...]``.

    ``mode``:
        "auto"  — (default) try text extraction first; if the mean page
                  has fewer than :data:`PDF_AUTO_IMAGE_CHARS_THRESHOLD`
                  characters (i.e. a scanned/image-only PDF), switch to
                  image mode. No extra cost on text-layer PDFs.
        "text"  — text extraction only (cheap; misses figures/scans)
        "image" — render each page to
                  ``./.cache/pdf-explore/{sha8}-{mtime}/dpi{N}/p{NNN}.png``
                  at ``dpi`` (default 100; ~1200×1600 for letter-size)
        "both"  — text + image

    ``pages``: optional 1-indexed list/range to restrict to (e.g. ``[3,4,5]``
    or ``range(1,11)``). With ``cache=True`` only a FULL read populates the
    in-memory cache; a later subset read is served from it for free, but a
    cold subset read re-parses each time (page renders are still reused on
    disk via the ``.cache/pdf-explore`` dir).

    Requires ``pypdfium2`` (permissively licensed). Falls back to ``pymupdf``
    if the user installed it, then to ``pypdf`` for text-only mode. Raises
    ``ImportError`` with a ``pip install`` recipe if none is available.
    """
    path = pdf_resolve(path)
    if not os.path.exists(path):
        raise FileNotFoundError(f"pdf_pages: {path!r} not found")
    if mode not in ("text", "image", "both", "auto"):
        raise ValueError(
            f"pdf_pages: mode must be 'text'|'image'|'both'|'auto', got {mode!r}"
        )
    # mode="auto" passes `pages` to two recursive calls — materialize a
    # one-shot iterable (generator/filter/iter) so the second call doesn't
    # see an exhausted object and silently return [].
    if pages is not None and not hasattr(pages, "__len__"):
        pages = list(pages)
    if mode == "auto":
        # Auto-detect scanned/image-only PDFs: parse text first, and if the
        # mean page has almost no extractable text (<80 chars — threshold
        # catches rasterized scans and slide-deck exports while leaving
        # sparse figure-pages alone), re-parse with rendering. Both parses
        # are cached independently so a re-scan is free.
        txt = pdf_pages(path, mode="text", pages=pages, dpi=dpi, cache=cache)
        if not txt:
            return txt
        mean_chars = sum(p["n_chars"] for p in txt) / len(txt)
        if mean_chars < PDF_AUTO_IMAGE_CHARS_THRESHOLD:
            return pdf_pages(path, mode="image", pages=pages, dpi=dpi,
                             cache=cache)
        return txt

    abspath = os.path.abspath(path)
    mtime = os.stat(abspath).st_mtime_ns
    key = (abspath, mtime, mode, int(dpi))
    want = None if pages is None else set(int(p) for p in pages)
    if cache and key in PDF_PAGE_CACHE:
        cached = PDF_PAGE_CACHE[key]
        if want is None:
            return [dict(p) for p in cached]
        hit = [dict(p) for p in cached if p["page"] in want]
        if len(hit) == len(want):
            return hit

    render = mode in ("image", "both")
    need_text = mode in ("text", "both")
    out = []
    img_dir = None
    if render:
        sha8 = hashlib.sha1(abspath.encode()).hexdigest()[:8]
        # Under .cache/ so page renders don't clutter the workspace. Keyed on
        # mtime + dpi so a re-render at a different dpi, or after the PDF is
        # modified in place, doesn't silently reuse stale PNGs.
        img_dir = os.path.join(
            os.getcwd(), ".cache", "pdf-explore",
            f"{sha8}-{mtime}", f"dpi{int(dpi)}",
        )
        os.makedirs(img_dir, exist_ok=True)

    try:
        import pypdfium2 as pdfium
    except ImportError:
        pdfium = None
    # pypdfium2's to_pil() lazy-imports PIL.Image; without pillow the render
    # path dies with a bare ModuleNotFoundError instead of the install recipe
    # below. When rendering is requested and pillow is absent, demote pdfium
    # so fitz (pix.save() writes PNG natively, no PIL dep) or the install
    # recipe gets a chance. Text-only pdfium needs no pillow.
    if pdfium is not None and render:
        try:
            import PIL.Image  # noqa: F401
        except ImportError:
            pdfium = None
    fitz = None
    if pdfium is None:
        try:
            import fitz  # pymupdf — user-installed fallback (AGPL-3.0)
        except ImportError:
            pass

    if pdfium is not None:
        try:
            doc = pdfium.PdfDocument(abspath)
        except Exception as e:
            if "password" in str(e).lower():
                raise ValueError(
                    f"pdf_pages: {path!r} is password-protected. Decrypt "
                    f"it first (e.g. `qpdf --decrypt --password=... in out` "
                    f"or pypdfium2.PdfDocument(path, password=pw))."
                ) from e
            raise
        try:
            total = len(doc)
            idxs = (
                range(total) if want is None
                else sorted(i - 1 for i in want if 1 <= i <= total)
            )
            for i in idxs:
                pg = doc[i]
                txt = ""
                if need_text:
                    tp = pg.get_textpage()
                    # pdfium emits \r\n line endings — normalize so char
                    # counts/thresholds match the historical extractor.
                    txt = tp.get_text_bounded().replace("\r\n", "\n")
                    tp.close()
                ip = None
                if render:
                    ip = os.path.join(img_dir, f"p{i + 1:03d}.png")
                    if not (cache and os.path.exists(ip)):
                        # dpi→scale: PDF native is 72dpi.
                        bmp = pg.render(scale=float(dpi) / 72.0)
                        bmp.to_pil().save(ip)
                out.append({
                    "page": i + 1,
                    "text": txt,
                    "n_chars": len(txt),
                    "image_path": ip,
                })
        finally:
            doc.close()
    elif fitz is not None:
        doc = fitz.open(abspath)
        try:
            if doc.needs_pass:
                raise ValueError(
                    f"pdf_pages: {path!r} is password-protected. Decrypt "
                    f"it first (e.g. `qpdf --decrypt --password=... in out` "
                    f"or `fitz.open(path).authenticate(pw)`)."
                )
            total = doc.page_count
            idxs = (
                range(total) if want is None
                else sorted(i - 1 for i in want if 1 <= i <= total)
            )
            for i in idxs:
                pg = doc.load_page(i)
                txt = pg.get_text("text") if need_text else ""
                ip = None
                if render:
                    ip = os.path.join(img_dir, f"p{i + 1:03d}.png")
                    if not (cache and os.path.exists(ip)):
                        # dpi→zoom: PDF native is 72dpi.
                        zoom = float(dpi) / 72.0
                        pix = pg.get_pixmap(matrix=fitz.Matrix(zoom, zoom))
                        pix.save(ip)
                out.append({
                    "page": i + 1,
                    "text": txt,
                    "n_chars": len(txt),
                    "image_path": ip,
                })
        finally:
            doc.close()
    else:
        if render:
            raise ImportError(
                "pdf_pages(mode='image'|'both') requires pypdfium2 and "
                "pillow (PNG encoding). Install with "
                "`pip install pypdfium2 pillow` and re-run."
            )
        try:
            from pypdf import PdfReader
        except ImportError as e:
            raise ImportError(
                "pdf_pages requires pypdfium2 or pypdf. Install with "
                "`pip install pypdfium2 pillow` and re-run (pillow is needed "
                "if you later render with mode='image')."
            ) from e
        reader = PdfReader(abspath)
        total = len(reader.pages)
        idxs = (
            range(total) if want is None
            else sorted(i - 1 for i in want if 1 <= i <= total)
        )
        for i in idxs:
            txt = reader.pages[i].extract_text() or ""
            out.append({
                "page": i + 1,
                "text": txt,
                "n_chars": len(txt),
                "image_path": None,
            })

    if cache and want is None:
        PDF_PAGE_CACHE[key] = [dict(p) for p in out]
    return out


def pdf_outline(path):
    """Build a table of contents from the PDF's EMBEDDED outline:
    ``[{"page": int, "heading": str, "level": int}, ...]`` in page order.

    Reads the PDF's own bookmarks (``get_toc()`` — free, instant; most
    LaTeX-sourced arXiv PDFs and published papers have one). Returns ``[]``
    when the document has no embedded outline — in that case read the page
    text with :func:`pdf_pages` and build the outline yourself from the
    section headings.

    Use this as the first navigation step::

        toc = pdf_outline("paper.pdf")
        for e in toc:
            print(f"p{e['page']:>3} {'  ' * (e['level'] - 1)}{e['heading']}")
        # → then pdf_pages("paper.pdf", pages=[the section you want])
    """
    abspath = os.path.abspath(pdf_resolve(path))
    toc = None
    try:
        import pypdfium2 as pdfium
        doc = pdfium.PdfDocument(abspath)
        try:
            toc = []
            for bm in doc.get_toc():
                dest = bm.get_dest()
                idx = dest.get_index() if dest else None
                # [level, title, 1-indexed page] — same shape as the
                # historical fitz get_toc(simple=True); unresolvable
                # destinations map to page 0 and are dropped below.
                toc.append([bm.level + 1, bm.get_title(),
                            (idx + 1) if idx is not None else 0])
        finally:
            doc.close()
    except Exception:  # noqa: BLE001
        try:
            import fitz  # pymupdf — user-installed fallback
            with fitz.open(abspath) as doc:
                toc = doc.get_toc(simple=True)  # [[lv, title, page], ...]
        except Exception:  # noqa: BLE001
            toc = None  # no parser / corrupt outline → no embedded TOC

    if not toc:
        return []
    fast = [{"page": int(p), "heading": str(t), "level": int(lv)}
            for lv, t, p in toc if p > 0]
    if not fast:
        return []
    # Sanity check: embedded bookmarks sometimes point to document-logical
    # pages (e.g. a LaTeX thesis whose hyperref anchors were generated before
    # front-matter was prepended), so page N in the TOC is really PDF page
    # N+offset. Verify 2-3 level-1 entries against the actual page text; warn
    # if none match.
    try:
        import unicodedata as _ud

        def _norm(s):
            return "".join(c for c in _ud.normalize("NFKD", s)
                           if c.isalnum()).lower()
        probes = [e for e in fast if e["level"] == 1][:3] or fast[:3]
        probe_pages = pdf_pages(abspath, pages=[e["page"] for e in probes],
                                mode="text")
        by_pg = {p["page"]: p["text"] for p in probe_pages}
        hits = 0
        for e in probes:
            h = _norm(e["heading"])[:40]
            t = _norm(by_pg.get(e["page"], "")[:1200])
            if h and h in t:
                hits += 1
        # A scanned PDF (no text layer) yields empty probe text — that's
        # "can't verify", not "offset bookmarks"; stay quiet.
        has_text_layer = any(
            len(by_pg.get(e["page"], "").strip())
            >= PDF_AUTO_IMAGE_CHARS_THRESHOLD
            for e in probes
        )
        if probes and hits == 0 and has_text_layer:
            print(
                "[pdf_outline] ⚠ embedded TOC page numbers don't match page "
                "text for any of "
                f"{len(probes)} sampled entries — the PDF's bookmarks likely "
                "use logical page numbers, not file page numbers "
                "(front-matter offset). Verify one entry against "
                "pdf_pages(path, pages=[N])[0]['text'] before navigating."
            )
    except Exception:  # noqa: BLE001
        pass  # best-effort sanity check only
    fast.sort(key=lambda e: e["page"])
    return fast


# Query terms shorter than this or in this set are ignored by pdf_scan's
# lexical scoring — they carry no topical signal.
_PDF_STOP = frozenset(
    "the a an and or of to in on for with from by as at is are be this that "
    "these those it its into via using use used we our their they them not "
    "can may will would should could has have had was were been being which "
    "what how why when where who whom than then also more most such between "
    "both each any all some other about over under above below within".split()
)


def pdf_scan(path, query, top_k=5, mode="text", pages=None, dpi=100):
    """Lexical relevance pre-filter — no LLM, fully deterministic.

    Scores every page by how well its text overlaps the query's content
    terms (distinct-term coverage + term density, with a bonus for an exact
    phrase hit) and returns the ``top_k`` candidate pages, each WITH its
    text, so YOUR base model can read the shortlist and make the final
    relevance judgment. This replaces the Claude-Science parallel-LLM scan:
    the mechanical pre-filter narrows a long document to a handful of pages
    cheaply; the reasoning is yours.

    Return shape::

        {"hits": [{"page": int, "score": float, "matched": [str],
                   "text": str, "image_path": str|None}, ...],
         "n_scanned": int}

    ``hits`` is sorted by score desc and truncated to ``top_k``. For reading
    a value/label off a FIGURE, pass ``mode="image"`` and open the returned
    ``image_path``. For a keyword you can name exactly (a DOI, an accession
    id, a token), :func:`pdf_grep` is more precise.
    """
    if not isinstance(query, str) or not query.strip():
        raise ValueError("pdf_scan: query must be a non-empty str")
    parsed = pdf_pages(path, mode=mode, pages=pages, dpi=dpi)
    if not parsed:
        return {"hits": [], "n_scanned": 0}

    from collections import Counter
    terms = {t for t in re.findall(r"[a-z0-9]+", query.lower())
             if len(t) > 2 and t not in _PDF_STOP}
    phrase = query.lower().strip()
    n_terms = len(terms) or 1
    hits = []
    for p in parsed:
        text = p.get("text") or ""
        low = text.lower()
        words = re.findall(r"[a-z0-9]+", low)
        if not words:
            score, matched = 0.0, []
        else:
            c = Counter(words)
            matched = sorted(t for t in terms if c.get(t))
            coverage = len(matched) / n_terms
            density = sum(c.get(t, 0) for t in terms) / len(words) * 1000
            score = coverage + min(density, 5.0) / 10.0
            if len(phrase) > 8 and phrase in low:
                score += 1.0  # exact-phrase bonus
        hits.append({"page": p["page"], "score": round(score, 3),
                     "matched": matched, "text": text,
                     "image_path": p.get("image_path")})
    hits.sort(key=lambda h: (-h["score"], h["page"]))
    nonzero = [h for h in hits if h["score"] > 0]
    hits = nonzero or hits
    if top_k is not None:
        hits = hits[: int(top_k)]
    return {"hits": hits, "n_scanned": len(parsed)}


def pdf_grep(path, pattern, flags=re.IGNORECASE, pages=None, context=False):
    """Regex sweep across every page — deterministic exhaustive extraction.

    The right tool for "list every X in this document" when X is
    pattern-shaped: DOIs, accession numbers, emails, URLs, figure/table
    labels, gene/protein ids, etc. Returns one row per page with ≥1 match::

        [{"page": int, "matches": [str], "lines": [str]?}, ...]

    ``pattern`` is a regex string or a compiled pattern. Set ``context=True``
    to also return the full text line of each match. Flatten + dedupe
    downstream, e.g.::

        rows = pdf_grep("paper.pdf", r"10\\.\\d{4,9}/[^\\s\"']+")   # DOIs
        dois = sorted({m for r in rows for m in r["matches"]})

    For fuzzy / semantic "find where X is discussed", use :func:`pdf_scan`
    and let your base model judge the shortlist.
    """
    rx = re.compile(pattern, flags) if isinstance(pattern, str) else pattern
    parsed = pdf_pages(path, mode="text", pages=pages)
    out = []
    for p in parsed:
        text = p.get("text") or ""
        matches = [m.group(0) for m in rx.finditer(text)]
        if not matches:
            continue
        row = {"page": p["page"], "matches": matches}
        if context:
            row["lines"] = [ln for ln in text.splitlines() if rx.search(ln)]
        out.append(row)
    return out
