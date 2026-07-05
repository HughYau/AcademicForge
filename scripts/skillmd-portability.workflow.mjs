export const meta = {
  name: 'skillmd-portability-rewrite',
  description: 'Rewrite claude-science SKILL.md files to be pure cross-agent skills (no host/API)',
  phases: [
    { title: 'Rewrite', detail: 'one agent per SKILL.md, edits in place' },
    { title: 'Verify', detail: 'check each rewrite for leftover Claude-Science-isms' },
  ],
}

const ROOT = '/data/pt_02977/QiuData/AcademicForge/skills/claude-science'

const SPEC = `
You are adapting ONE Claude Science skill's SKILL.md so it works as a PURE,
provider-agnostic skill in any agent (Claude Code, Codex CLI, OpenCode, …).

PHILOSOPHY (non-negotiable):
- These are now PURE skills: kernel.py is deterministic Python and there is NO
  \`host\` runtime, NO LLM API, NO key, NO config. The BASE MODEL (whatever agent
  is running — you) does ALL the LLM judgment in its own context.
- Wherever the old skill relied on host.llm() to classify/extract/summarize/
  rank/review, the NEW skill hands the reader the raw material and tells THEM to
  do that reasoning themselves. Do not invent a replacement API. Do not tell the
  reader to call any LLM endpoint.

MANDATORY EDITS:
1. SETUP BLOCK. If this skill has a kernel.py, insert a self-contained "## Setup"
   section near the top (right after the opening intro, before the how-to). Use
   EXACTLY this shape, filled in for this skill (keep it self-contained — do NOT
   reference PORTABILITY.md or any shared file; per-sub-skill installs don't ship
   sibling files):

   ## Setup (any agent, no API key)
   This is a **pure skill** — \`kernel.py\` is deterministic Python and *you* (the
   base model) do all the reasoning. There is no \`host\` runtime and no LLM API.
   Load the helpers once per session in a Python cell:
   \`\`\`python
   exec(open("<this skill's directory>/kernel.py").read())
   \`\`\`
   Nothing auto-loads it outside Claude Science. Then call the helpers directly.
   <If the skill needs pip packages, add: Dependencies: \`pip install ...\`.>

2. Replace every claim that kernel.py is "auto-injected"/"auto-loaded into the
   kernel when the skill loads" with a pointer to the Setup block ("load it via
   exec — see Setup"). If it is not defined, you haven't exec'd kernel.py.

3. Swap Claude-Science-only capabilities for the pure-skill equivalent:
   - host.llm(...) → YOU do it: the helper gives you text/images; you produce the
     judgment/extraction/summary/ranking in your own reasoning. Describe the
     concrete workflow (parse → read → decide), don't hand-wave.
   - host.view_image(path, crop=...) → the kernel writes PNGs to disk; open/attach
     them with your agent's image tool (e.g. Read the PNG path).
   - host.delegate(...) / "sub-agent per X" / "repl tool" fan-out → do the sub-tasks
     yourself, sequentially; note that on platforms with a sub-agent tool (Claude
     Code's Task) you MAY parallelize, but the skill must work single-agent. Remove
     the repl-vs-python tool distinction.
   - {{artifact:ID}}, artifact version_ids, save_artifacts, "project artifacts" →
     filesystem paths; save outputs as ordinary files.
   - read_file(pages=...) → prefer the kernel (parse with the helper, write text to a
     file, read that file); or your agent's own file/PDF read tool. Drop
     Claude-Science context-management framing like "pages drop from context after
     one turn", ".cache auto-attach", "auto_view_images".
   - manage_packages/manage_environments/domain-env → \`pip install ...\` via the shell.
   - host.compute / wait_for_notification / compute_details / compute ledger → call the
     provider SDK directly (e.g. \`modal run\`) synchronously; mark these as
     Claude-Science-only orchestration that has no standard-agent equivalent.
   - web_search / search_skills / skill({...}) → your agent's own web-search / tool
     discovery; drop CS-specific calls.
   - fold_cue frontmatter, "[llm] kernel_default_model", hardcoded model ids like
     "claude-haiku-4-5" → remove; there is no model to pick (the base model is
     whatever is running).

4. PRESERVE all portable content — the actual method, the recipe logic, the design
   rules, the voice. Make SURGICAL edits: change the Claude-Science-isms, insert the
   Setup block, reframe the LLM-judgment sections. Do NOT gut good prose or shorten
   valuable explanation. The result must read like a native cross-agent skill, not a
   patched one.

5. Keep the YAML frontmatter's name/license intact. You MAY tighten the description
   if it references Claude-Science-only behavior, but keep it accurate and similar
   length. Remove a \`fold_cue:\` line if present.

Edit the SKILL.md IN PLACE with the Edit/Write tools. Read the current file first.
Return a short list of the changes you made and confirm no host.* / {{artifact /
host.view_image / host.delegate / manage_packages / save_artifacts / read_file(pages
remain (except where you explicitly kept one as a documented "Claude-Science-only,
no equivalent" note).
`

// Per-skill specifics: new kernel surface + the key CS-isms recon found.
const SKILLS = [
  {
    key: 'pdf-explore',
    surface: `NEW kernel.py surface (pure): pdf_pages(path,mode,pages,dpi,cache) → [{page,text,n_chars,image_path?}]; pdf_outline(path) → [{page,heading,level}] from the EMBEDDED TOC only ([] if none — then build the outline yourself by reading page text); pdf_scan(path,query,top_k,mode) → a LEXICAL relevance PRE-FILTER (no LLM) returning {hits:[{page,score,matched,text,image_path?}],n_scanned} — it narrows a long doc to candidate pages cheaply; YOU read the shortlist's text and make the final relevance judgment; pdf_grep(path,pattern) → regex sweep for exhaustive pattern extraction (DOIs, accession ids, …) → [{page,matches,lines?}]; pdf_resolve(path). REMOVED: pdf_map, pdf_extract, PDF_DEFAULT_MODEL, all host.llm fan-out. Dependencies: pip install pypdfium2 pillow.`,
    notes: `This is the flagship — set the template quality bar. The old value prop ("scan 100 pages in parallel with cheap haiku") is replaced by: parse once with pdf_pages (persistent text, not vanishing vision), use pdf_outline/pdf_scan to NARROW, then read only the pages you need and reason yourself. For "list every X" use pdf_grep (pattern-shaped) or read the text and extract. For reading a value off a figure: pdf_pages(mode="image", dpi=200) then open the PNG. Remove the fold_cue line, the read_file-vision-drop framing, host.llm reduce calls, host.artifact_path/version_id path input, PDF_DEFAULT_MODEL/[llm] notes, and .cache auto-attach language.`,
  },
  {
    key: 'paper-narrative',
    surface: `NEW kernel.py surface (pure): paper_brief_schema(); paper_brief_prompt(abstract_text, figure_claims) → returns the prompt YOU answer to write the brief (emit JSON matching paper_brief_schema); paper_brief_scaffold(...) → {prompt,schema,figures}; narrative_review_schema(); narrative_review_task(brief, deck_path, rules_path=None) → the handling-editor prompt YOU (or a sub-agent) answer after viewing the figures PDF, embedding FILE PATHS not artifact ids. REMOVED: derive_paper_brief (the host.llm call) — the base model writes the brief itself.`,
    notes: `The two entry points are now: (1) call paper_brief_prompt(...) and YOU write the paper_brief JSON; (2) call narrative_review_task(brief, deck_path, rules_path) and YOU play the handling editor over the figures PDF, emitting JSON matching narrative_review_schema(). deck/rules are file paths (open/attach them). Replace @manuscript.tex/@all_figures.pdf CS-attachment framing and "search project artifacts" with file paths / searching the filesystem.`,
  },
  {
    key: 'figure-composer',
    surface: `NEW kernel.py surface (pure, PIL/geometry + builders): figure_outline_schema() (panels carry data_path, not data_vid); grid_geom/panel_px/panel_xy; panel_task(outline,letter,fig_label,rules_ref) → the per-panel maker prompt; compose_crops(outline,...) → {letter:(x0,y0,x1,y1)} PIL crop boxes; compose_figure(outline,panel_paths,out_path,...) → tiles panel PNGs into a composite; group_fixes_by_panel; review_schema(); composite_review_task(composite_path,outline,rules_path,prev_path,...) → adversarial review prompt with FILE PATHS; apply_outline_revisions; derive_outline_prompt(claim,data_hints) → the prompt YOU answer (looking at a figure PNG) to reverse-engineer an outline. REMOVED: derive_outline's host.llm vision call.`,
    notes: `HARDEST rewrite: the core loop was host.delegate (one sub-agent per panel, in the repl tool). Re-express it portably: generate each panel yourself by following panel_task(outline, letter) — one at a time — then compose_figure() to tile them, then open the composite and run composite_review_task as an adversarial self-review (or a sub-agent if your platform has one), regenerate flagged panels, repeat. Note Claude Code users MAY parallelize panels with the Task tool. Everything uses file paths (panel_X.png, composite.png), not artifact vids. derive_outline → derive_outline_prompt: YOU open the figure PNG and emit the outline JSON. Replace host.view_image with open-the-PNG and save_artifacts with saving files.`,
  },
  {
    key: 'literature-review',
    surface: `kernel.py surface (already pure HTTP/stdlib): verify_dois, crossref_lookup, search_openalex, expand_citations, extract_dois, style_pass. Config via env: OPENALEX_API_KEY (required for OpenAlex steps), HOST_USER_EMAIL (optional CrossRef polite-pool email, falls back to git config user.email). No host, no LLM.`,
    notes: `This skill already had the correct exec-fallback pattern — keep/standardize it into the Setup block. Add the env-var note (OPENALEX_API_KEY, HOST_USER_EMAIL). Replace web_search/search_skills({prefix:"mcp-"})/domain-connector framing with "your agent's own web search / MCP tools", and save_artifacts with writing the review to a .md file. The synthesis/writing itself is done by you (the base model) — that's already how it reads.`,
  },
  {
    key: 'figure-style',
    surface: `kernel.py surface (already pure matplotlib): apply_figure_style, set_frame, panel_letter, focal_palette (returns a LIST parallel to labels), bar_with_points, strip_with_median, goodness_arrow, two_tier_label, end_of_line_labels, panel_crops (returns {letter:(x0,y0,x1,y1)}). No host.`,
    notes: `Mostly portable correctness prose — light touch. Add the Setup block (helpers are pure matplotlib; no extra deps beyond matplotlib/numpy). Replace host.view_image (the §9.2 QA loop: panel_crops → open each crop PNG) and save_artifacts with saving files. Keep all the design-rule content intact.`,
  },
  {
    key: 'scvi-tools',
    surface: `kernel.py surface (already pure): h5ad_safe_obs(df) → coerces obs dtypes so anndata.write_h5ad() works. No host. The scVI/scANVI recipe itself is plain scanpy/scvi.`,
    notes: `~75% is portable scanpy/scvi. Add the Setup block for h5ad_safe_obs (exec kernel.py). The "Remote compute" section (host.compute.create('byoc:modal'), submit_job, wait_for_notification, save_artifacts, compute_details) is Claude-Science orchestration — reframe it to call the Modal SDK directly / synchronously (\`modal run\`), and clearly mark host.compute/wait_for_notification as Claude-Science-only with no standard-agent equivalent. Keep the scientific recipe unchanged.`,
  },
]

phase('Rewrite')
const results = await pipeline(
  SKILLS,
  (s) => agent(
    `${SPEC}\n\nSKILL: ${s.key}\nFILE: ${ROOT}/${s.key}/SKILL.md\n\n` +
    `${s.surface}\n\nSPECIFIC GUIDANCE:\n${s.notes}\n\n` +
    `Read ${ROOT}/${s.key}/SKILL.md, then edit it in place per the spec.`,
    { label: `rewrite:${s.key}`, phase: 'Rewrite', agentType: 'general-purpose',
      schema: {
        type: 'object',
        properties: {
          skill: { type: 'string' },
          changes: { type: 'array', items: { type: 'string' } },
          remaining_cs_isms: { type: 'array', items: { type: 'string' } },
          setup_block_added: { type: 'boolean' },
        },
        required: ['skill', 'changes', 'setup_block_added'],
      } }
  ),
  (rw, s) => agent(
    `Verify the cross-agent rewrite of ${ROOT}/${s.key}/SKILL.md. This should now be ` +
    `a PURE skill: no host runtime, no LLM API, base model does the judgment.\n\n` +
    `Read the file and check:\n` +
    `1. Is there a self-contained "## Setup" section with the exec(open(.../kernel.py)) load line? ` +
    `(required since this skill has a kernel.py)\n` +
    `2. Do any of these Claude-Science-only patterns REMAIN unaddressed (grep the file): ` +
    `host.llm, host.view_image, host.delegate, host.artifact_path, host.credentials, ` +
    `host.get_user_email, host.compute, {{artifact:, save_artifacts, manage_packages, ` +
    `manage_environments, wait_for_notification, "auto-inject", "auto-loaded", fold_cue, ` +
    `read_file(pages, a hardcoded model id like claude-haiku-4-5? ` +
    `(An explicitly-labeled "Claude-Science-only, no equivalent" note is acceptable.)\n` +
    `3. Does the SKILL.md match the ACTUAL new kernel surface (no references to removed ` +
    `functions like derive_paper_brief, pdf_map, pdf_extract, derive_outline, data_vid)?\n` +
    `New surface: ${s.surface}\n` +
    `4. Was portable content preserved (not gutted)?\n\n` +
    `Report ok=true only if 1-3 are clean. List concrete issues with line snippets.`,
    { label: `verify:${s.key}`, phase: 'Verify', agentType: 'general-purpose',
      effort: 'medium',
      schema: {
        type: 'object',
        properties: {
          skill: { type: 'string' },
          ok: { type: 'boolean' },
          issues: { type: 'array', items: { type: 'string' } },
        },
        required: ['skill', 'ok', 'issues'],
      } }
  ),
)

const bad = results.filter(Boolean).filter((r) => r && r.ok === false)
log(`rewrite+verify done: ${results.filter(Boolean).length}/${SKILLS.length}; ${bad.length} need follow-up`)
return { verified: results.filter(Boolean), needs_followup: bad }
