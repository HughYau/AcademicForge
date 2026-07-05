# Running Claude Science skills as pure skills (any agent, no API key)

The skills in `skills/claude-science/` originally ran inside Anthropic's
proprietary **Claude Science** kernel, where an auto-injected `host` object
bridged to the platform's LLM client, credential store, and artifact registry.
Outside that runtime (Claude Code, Codex CLI, OpenCode, or any other agent)
`import host` does not exist, so every LLM-backed helper used to crash.

These skills have been re-architected as **pure skills**:

- **No `host` runtime, no LLM API, no key, no configuration.** Every
  `kernel.py` is now self-contained, deterministic Python (PDF parsing, DOI
  verification over HTTP, figure composition with PIL, matplotlib styling …).
- **The base model does the reasoning.** Wherever the original called
  `host.llm()` to classify, extract, summarize, rank, or review, the skill now
  gives *you* — whatever base model is running the agent — the raw material and
  asks you to do the judgment in your own context. That is what makes the
  skills work identically on every platform.

This is the philosophy behind the port and the contract every skill follows.

## Loading a skill's helpers

Nothing auto-injects `kernel.py` outside Claude Science. Load it once per
session in a Python cell (run via your agent's code / shell tool):

```python
exec(open("<this skill's directory>/kernel.py").read())
# e.g. exec(open(".claude/skills/cs-pdf-explore/kernel.py").read())
```

Then call the helpers directly — they need no `import`, no API key, and no
network for local work. If a helper is not defined, you have not exec'd
`kernel.py` yet. Each `kernel.py` docstring lists its surface.

## What replaces each Claude-Science-only capability

| Claude Science | In a standard agent (pure skill) |
|---|---|
| `host.llm(...)` per-page fan-out | The deterministic helper hands you the text/images; **you** read it and produce the classification / extraction / summary / ranking yourself. |
| `host.view_image(path, crop=...)` | The kernel writes PNGs to disk (`pdf_pages(mode="image")`, `compose_crops`, `panel_crops`); open/attach them with your agent's image tool (e.g. `Read`). |
| `host.delegate(...)` sub-agent fan-out | Do the sub-tasks yourself, sequentially. On platforms with a sub-agent tool (Claude Code's `Task`) you may parallelize, but the skill works single-agent. |
| `host.get_user_email()` | `HOST_USER_EMAIL` env var (falls back to `git config user.email`). |
| `host.credentials.request("openalex")` | `OPENALEX_API_KEY` env var. |
| `host.artifact_path(vid)` / `{{artifact:ID}}` / `save_artifacts` | Filesystem paths; save outputs as ordinary files. |
| `host.compute` / `wait_for_notification` | Call the provider SDK directly (e.g. `modal run`), synchronously. |
| `read_file(pages=…)`, `manage_packages(…)`, `web_search`, `skill({…})`, the `repl`-vs-`python` split, `fold_cue` frontmatter | Use your agent's native equivalents; for packages, `pip install …` via the shell. |

## Environment variables (only literature-review needs any)

| Variable | Used by | Purpose |
|---|---|---|
| `OPENALEX_API_KEY` | literature-review | Required for OpenAlex steps (`search_openalex`, `expand_citations`). Free at <https://openalex.org/settings/api>. |
| `HOST_USER_EMAIL` | literature-review | Optional CrossRef/doi.org polite-pool contact email. Falls back to `git config user.email`; set empty to opt out. |

Everything else runs with zero configuration.
