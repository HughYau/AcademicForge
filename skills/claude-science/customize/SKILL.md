---
name: customize
description: Create, configure, and maintain custom agent profiles and author new skills via the `repl` tool. Use when the user wants to create an agent profile, build a custom agent, modify agent capabilities, attach or detach skills/connectors on a profile, author a skill, or inspect which connectors and tools are available. Also use whenever you need the `host.agents.*` or `host.skills.*` Python SDK.
license: Apache-2.0
---

# Customize

Build and maintain **agent profiles** and **skills** programmatically via the
`repl` tool using `host.agents.*` and `host.skills.*`.

A **profile** is a named bundle that shapes how an agent behaves:

- **`system_prompt`** — the profile's **identity**. This is the opening of the
  agent's system prompt; it REPLACES the generic "You are Claude Science" base identity.
  Write it in second person, lead with `You are {display_name}, ...`, state what
  the agent specializes in and what it does NOT do. Everything else (tool-usage
  rules, working-style bullets, scope guardrail) is inherited automatically —
  don't restate it.
- **`display_name` / `description` / `icon_key` / `color_key`** — picker metadata.
- **`skill_names`** (optional restriction) — by default a profile sees the
  **full live skill catalog** via `search_skills` / `skill(...)`, same as the
  main agent. Pass an explicit list ONLY to deliberately restrict it; `[]` creates
  a zero-skill specialist. **Restricting skills also restricts connectors** —
  a single `unrestricted` flag governs both; passing `skill_names` flips the
  profile to curated mode and starts it with **zero** connectors (see next).
- **Connector access** — an **unrestricted** profile (the default) reaches
  **every connector** (bundled + custom + authorized directory), same as the
  main agent; use `detach_connector` to subtract specific ones. A **curated**
  profile (one created with an explicit `skill_names` list, or flipped via
  `{"unrestricted": False}`) starts with **no connectors** — reach is exactly
  what you `attach_connector`.
- **`excludedTools`** — per-tool blocklist applied *after* connectors resolve.
  Use to strip specific high-risk or irrelevant tools from an otherwise-useful
  connector. **Per-connector, not a profile field** — set via
  `attach_connector(..., include_tools_pattern=/exclude_tools_pattern=)`; the
  profile's `excludedTools` in `list()` is the read-only aggregation across all
  its attached connectors. Patterns match the connector's **bare** tool names
  (e.g. `'^list_marts$'`, as returned by `list_connectors(name)['tools']`); the
  aggregated `excludedTools` entries are stored fully-qualified as
  `mcp_<connector>_<tool>` since the list spans every attached connector.

---

## Python SDK

All calls run via the **`repl` tool** (see "Runs via the `repl` tool"
below). Return values are plain dicts/lists; errors raise `RuntimeError`
with a `host.agents.*:` / `host.skills.*:` prefix.

### `host.agents`

```python
host.agents.list()
# → [{"name", "displayName", "description", "source", "enabled",
#     "systemPrompt", "iconKey", "colorKey",
#     "skillNames": ["skill", ...], "connectors": ["name", ...],
#     "excludedTools": [...]}, ...]
#   (Return-dict keys are camelCase — wire shape, not kwarg names.)
#   `connectors` is a list of connector names (strings, same as skillNames) —
#   pass one to attach_connector/detach_connector or list_connectors(name).

host.agents.create(name, display_name, description,
                     system_prompt="", skill_names=None)
# name: 2–32 chars, UPPERCASE letters / digits / underscores only —
#       e.g. "RNASEQ_REVIEWER". Lowercase / dashes are rejected.
#       display_name is the human-friendly picker label.
# skill_names controls catalog visibility:
#   - leave it unset → the profile sees the FULL live skill catalog, same as
#     the main agent — skills published later appear automatically. It also
#     gets every connector the main agent has, resolved dynamically — new
#     connectors added later appear automatically too. This is the default;
#     don't pass a list unless you mean to restrict.
#   - pass a list (including []) → restricts `search_skills`/`skill(...)` to
#     EXACTLY those names. [] creates a zero-skill specialist.
# → the stored profile record (same shape as one list() entry)

host.agents.update(name, patch)
# patch: dict of fields to change — any of display_name, description,
#        system_prompt, skill_names, unrestricted, icon_key, color_key
#        (camelCase also OK).
# patch["skill_names"] is an EXACT REPLACE of the whole skill list and flips
# the profile to restricted mode — anything you omit is DETACHED. To add or
# remove a few skills, use attach_skill / detach_skill — they work on both
# restricted AND unrestricted profiles without changing the mode.
#
# If you do need a full-list replace, CHECK cur["unrestricted"] FIRST: on an
# unrestricted profile cur["skillNames"] is the lossy disk-cache view (not
# the full live catalog), so `cur["skillNames"] + ["x"]` would permanently
# freeze the profile to that partial list. The safe pattern:
#   cur = [a for a in host.agents.list() if a["name"] == name][0]
#   if cur["unrestricted"]:
#       host.agents.attach_skill(name, "new-skill")   # stays unrestricted
#   else:
#       host.agents.update(name,
#           {"skill_names": cur["skillNames"] + ["new-skill"]})
# (return-dict keys are camelCase — read "skillNames", write "skill_names")
# patch["unrestricted"] = True → back to the full live catalog + all
# connectors (undoes a skill_names restriction).
# → updated profile record
# (excludedTools is NOT a patch field — it's per-connector; use
#  attach_connector's include_tools_pattern/exclude_tools_pattern below.)

host.agents.switch(name)
# Ask to continue THIS conversation as `name`. Shows the user an approval
# card; on Allow, the switch takes effect on their NEXT message (the current
# turn finishes as the current profile). On decline, tell the user they can
# select the profile from the session config popover on any new conversation.
# → {"switched": True, "name", "displayName"}

host.agents.delete(name)
# → {"deleted": name}

host.agents.attach_skill(name, skill)
host.agents.detach_skill(name, skill)
# → updated profile record

host.agents.attach_connector(name, connector,
                               include_tools_pattern=None,
                               exclude_tools_pattern=None)
host.agents.detach_connector(name, connector)
# → updated profile record. Omit both patterns on a fresh attach to expose
#   every tool the connector offers; re-attaching an already-attached
#   connector without patterns preserves its existing exclusion list (pass
#   include_tools_pattern='.*' to clear it). Patterns match the connector's
#   BARE tool names (as returned by list_connectors(name)['tools'], e.g.
#   '^list_marts$'); the resulting excludedTools entries are stored
#   fully-qualified as mcp_<connector>_<tool>.

host.agents.list_connectors(connector_name=None)
# no arg → [{"name", "displayName", "source", "description",
#            "authState", "attachedAgents": [...]}, ...]
# with connector_name → single dict with an extra
#   "tools": [{"name", "description"}, ...]
```

### `host.skills`

```python
host.skills.list()
# → [{"name", "origin", "description"}, ...]
#   origin: "anthropic" (bundled, read-only — fork under a new name),
#           "organization"/"personal" (editable), "draft" (local, unpublished)

host.skills.read(name, path="SKILL.md")
# → {"name", "path", "content": "..."}

host.skills.edit(name, path, content, old_string=None)
# old_string=None → create `path` with `content` (fails if the file already
#                   exists — read it, then edit with a non-empty old_string)
# old_string=str  → str_replace the single exact match (rejected unless it
#                   matches exactly once — add surrounding context if needed)
# → {"action", "path", "draft_path", "note"}

host.skills.publish(name, overwrite=False)
# publish takes NO content args — write SKILL.md via .edit() first.
# → {"status": "published", "skill_id", "name", "note"}

host.skills.delete(name)
# draft → removes local dir; org/personal → unpublishes + removes local
# cache; anthropic bundled → protected.
# → {"deleted": name}  (plus "unpublished": True for published skills)
```

### Runs via the `repl` tool

`host.agents.*` / `host.skills.*` execute in the **control-plane
kernel** — a separate Python process from your `python` cells, reached via
the **`repl` tool** (not the `python` tool). It shares your workspace
directory (cwd) but **not** memory, so variables from `python` cells aren't
visible there and vice-versa. To hand results across, write to a file —
same pattern as Python↔R:

```python
# repl tool
import json, os
os.makedirs("handoff", exist_ok=True)
profiles = host.agents.list()
json.dump(profiles, open("handoff/agents.json", "w"))
```

```python
# python tool
import json, pandas as pd
profiles = json.load(open("handoff/agents.json"))
pd.DataFrame(profiles)[["name", "source", "enabled"]]
```

---

## Workflow: scope → draft → review → create

**Do not call `generate_plan` for profile CRUD.** This is a single
scope→draft→confirm loop; `ask_user` (step 4) is the review gate. A plan
adds a second approval that duplicates the `ask_user` confirmation and
drags in step-status bookkeeping that fights this workflow.

**User approval.** Most `host.agents.*` / `host.skills.*` calls apply
immediately — `create`/`update` (including unrestricted),
`attach_*`/`detach_*`, and `skills.publish`/`skills.edit` are pre-approved
at session start and the cell does NOT pause. An approval card (cell
pauses, resumes automatically on Allow — you don't retry) appears only
for the calls that **hand off identity or free a granted name**:

- `host.agents.switch(name)` — per-target; Allow covers this name only
- `host.agents.update(name, {"name": ...})` (rename) — per-target
- `host.agents.delete(name)` / `host.skills.delete(name)` — **one card
  per project**: the first delete shows a card; "Allow for this project"
  covers every subsequent delete in this project, including bulk
  teardown. Do NOT tell the user they'll see N cards for N deletes.

The name is read from the runtime call for `switch` and rename, so both
literal and variable names work (`host.agents.switch("FOO")` or
`host.agents.switch(name_var)`); keep the `ask_user` review step
so the click is a quick confirm, not a surprise. After the call returns,
read back (`host.agents.list()`) to confirm the actual state — don't
narrate an expected card.

### Reading existing profiles

Call `host.agents.list()` to see the user's current profiles so you don't
duplicate an existing agent. The main agent's bundled profile is protected —
it cannot be renamed or deleted.

### 1. Scope first

What is this agent *for*? A profile should have one job. Pick an UPPER_SNAKE
name (`RNASEQ_REVIEWER`, not `RNA-seq review helper`). Use `ask_user` if the
name or scope is unclear — profiles are user-visible in the picker.

### 2. Write the identity

`system_prompt` is the agent's opening paragraph — it replaces the base
identity, it's not an addendum. Lead with `You are {display_name}.` State the
specialization and the boundaries ("You handle X, Y, Z. You do not handle
..."). Keep it under ~200 words; the heavy how-to lives in skills, not the
prompt.

### 3. Ask: full access or a subset?

Before creating, `ask_user` whether this profile should have **full access**
(the live skill catalog and every connector — same reach as the main agent;
new skills and connectors appear automatically) or a **restricted subset**
(a fixed list you'll curate together). Don't infer this from the role
description — a narrowly-described specialist may still want full reach,
and a broadly-described one may want a tight loadout. Pair this with the
name/prompt review in step 4 so it's one round-trip.

### 4. Review with the user

Show the proposed name, display name, description, `system_prompt`, and the
user's full-vs-subset choice from step 3. `ask_user` to confirm before
writing. If they chose a subset, list the proposed skills/connectors here.

### 5. Create

Call `host.agents.create(name, display_name, description, system_prompt=...)`.
If the user chose **full access**, leave `skill_names` unset. If they chose a
**subset**, pass `skill_names=[...]` with the agreed list — **this flips the
profile to curated mode and starts it with zero connectors**, so attach the
agreed connectors after create as in step 6. For edits to an existing profile,
use `host.agents.update(name, {...})` with targeted fields; prefer
`host.agents.attach_skill(...)` / `host.agents.detach_skill(...)` and
`host.agents.attach_connector(...)` / `host.agents.detach_connector(...)`
over wholesale `skill_names` replacement so you don't clobber the user's own
edits.

After the profile exists, **offer to switch to it**:
`host.agents.switch(name)`. The user sees an approval card; on Allow, this
conversation continues as the new specialist from their next message. If they
decline, tell them they can select it from the session config popover on any
new conversation.

### 6. Restricting the loadout (when the user chose a subset)

If the user chose a subset in step 3, curate after create:

- **Skills**: `host.agents.update(name, {"skill_names": [...]})` with the
  exact list, or `detach_skill` one at a time. Check `host.skills.list()`
  for available names. On `update`, `skill_names` is an exact replace — never
  send a partial list to "add"; fetch the current `skillNames` (camelCase in
  the return dict), modify, send back.
- **Connectors**: a curated profile (created with an explicit `skill_names`
  list, or flipped via `{"unrestricted": False}`) starts with **NO
  connectors** — reach is exactly what you attach. Call
  `host.agents.list_connectors()` to see every available connector (bundled +
  directory + user-added MCP) with its auth state, then
  `host.agents.attach_connector(name, connector_name)` for **each** connector
  the user agreed to keep. Use `include_tools_pattern=`/`exclude_tools_pattern=`
  on the attach call to scope which tools the profile gets (omit both to
  expose every tool; re-attaching without patterns preserves the existing
  exclusion list — pass `include_tools_pattern='.*'` to clear). A connector
  with `authState` other than `"authorized"` or `"not-required"` must be
  connected via the Connectors panel before it can be attached.
  `detach_connector` only removes an explicit attachment; on a curated
  profile there is nothing to detach — don't use it to "restrict".
- After attaching, read back `host.agents.get(name)["connectors"]` to confirm
  the reach matches what you told the user.
- To undo a restriction: `host.agents.update(name, {"unrestricted": True})`.

### 7. Set up the environment

After the profile exists, propose a conda environment for it: name it after the
profile (lowercase slug, e.g. `rnaseq-reviewer`), pick `python` or `r` based on
the skills you attached, and list the packages those skills need. `ask_user` to
confirm the package list, then call
`manage_environments(mode="create", name="<slug>", packages=[...])` and, if
anything further is needed,
`manage_packages(mode="install", environment="<slug>", packages=[...])`. The
profile uses this env by default; the system-owned `python` and `r` skeletons
remain available as fallbacks.

### What makes a good profile

- **A sharp identity.** One job, stated clearly in `system_prompt`. Full
  catalog access by default — restrict the loadout only when the user asks.
- **Composable.** Reuse existing skills; don't inline workflow steps into
  `system_prompt` that belong in a skill.
- **Safe by default.** If a connector is powerful, exclude the tools the agent
  doesn't need.

---

## Authoring skills

For the full skill-authoring guide (anatomy, progressive disclosure, eval loop,
description optimization), first load it:

```python
skill({"skill": "skill-creator"})
```

Then use the `host.skills` SDK via the `repl` tool to write and publish:

```python
# draft
host.skills.edit("my-skill", "SKILL.md", """---
name: my-skill
description: ...
---

# My Skill
...
""")

# bundle a helper
host.skills.edit("my-skill", "kernel.py", "def helper(x): ...\n")

# inspect / iterate
print(host.skills.read("my-skill")["content"])

# publish to the live skill set
host.skills.publish("my-skill")
```

Once published, the skill is in the live catalog — every unrestricted profile
(including the main agent and any profile created with the default) sees it
immediately. For a restricted profile, attach it explicitly with
`host.agents.attach_skill(profile_name, "my-skill")`.

---

## Kernel sidecars (`kernel.py` / `kernel.R`)

If a skill's workflow depends on reusable helper functions, ship them as
`kernel.py` (and/or `kernel.R`) at the skill root. When any agent calls
`skill({skill: <name>})`, that file is executed in its persistent python/R kernel and
the tool result reports which top-level names were defined — so SKILL.md can
say "call `annotate_df(df)`" and the function already exists.

Sidecars are validated before execution so that loading a skill only **defines**
names — nothing author-written runs at load time. Allowed at the top level:

- `def` / `async def` (no decorators). Default argument values must be
  literals — `def f(url=MY_CONSTANT)` gets the whole file rejected. Wrap
  constants with an explicit `is None` check: `def f(url=None):` then
  `if url is None: url = MY_CONSTANT` (not `url = url or MY_CONSTANT`,
  which also replaces `0`, `""`, `[]`).
- `import` / `from … import name` (no `*`). Defer third-party imports to
  inside function bodies — the skeleton `python` env ships stdlib + a small
  starter set (numpy, pandas, scipy, matplotlib, seaborn, pillow), so e.g.
  `import requests` at module scope surfaces a load error on every fresh
  kernel. Import errors don't fail the skill load; the agent sees the
  traceback and can `manage_packages` then re-load.
- Assignment of a **literal** constant to a plain name (e.g. `VERSION = "1"`,
  `LIMITS = (1, 2, 3)`). Computed values like `os.path.join(...)` are
  rejected — move them into a function body.

Anything else at the top level (classes, calls, `if`/`for`, non-literal
assigns) is rejected with `[kernel.py rejected] …`. Names starting with `_`
are reserved by the loader and cannot be bound at the top level (use
`import os` and reference `os.path` inside functions, not
`import os as _os`). Function **bodies** are not restricted — they run only
when the agent calls them in a `python` cell.

Keep `kernel.py` small and self-contained (same guidance applies to
`kernel.R`). If a helper wants more than ~100 lines, trim it to the core
operations the agent actually calls; `scripts/` is for standalone CLI
tools run via bash, not for backing the sidecar. For `kernel.py`, the
skill directory is not on `sys.path`, so `from scripts.X import …` fails
— but the directory **is** on disk and readable. A Python sidecar function
can locate it via its own `co_filename` to shell out to a `scripts/` tool:

```python
# kernel.py
import os, sys, subprocess

def run_pipeline(cfg_path):
    here = os.path.dirname(sys._getframe().f_code.co_filename)
    if not here:
        raise RuntimeError("skill dir unavailable in this runtime")
    tool = os.path.join(here, "scripts", "pipeline.py")
    return subprocess.run([sys.executable, tool, cfg_path],
                          capture_output=True, text=True, check=True).stdout
```

`__file__` is not set (sidecars share one kernel namespace, so a global
`__file__` would point at whichever skill loaded last). `co_filename` is
per-function and normally points at this skill's on-disk `kernel.py`; in
rare cases (e.g. when the loader can't resolve the skill dir on disk) it
falls back to the bare name `"kernel.py"` — hence the `if not here` guard
above.

The runtime exports `PYTHONSAFEPATH=1`, which the `subprocess.run` child
inherits — so `python scripts/pipeline.py` does NOT put `scripts/` on the
child's `sys.path`. A multi-file tool that does sibling imports must add
`sys.path.insert(0, os.path.dirname(__file__))` at the top of its entry
script (or pass `env={**os.environ, "PYTHONSAFEPATH": ""}` to
`subprocess.run`). If the child exits non-zero, `capture_output=True`
hides the traceback — inspect `CalledProcessError.stderr`.

`kernel.R` has no runtime analogue of `co_filename` (the R loader parses
with `keep.source=FALSE`), so an R sidecar that needs to reach `scripts/`
should take the path as an argument from the caller.

Minimal example:

```python
# kernel.py
import pandas as pd  # starter-set package — OK at module scope

def annotate_df(df: pd.DataFrame, gene_col: str = "gene") -> pd.DataFrame:
    """Attach HGNC symbols; see SKILL.md ## Workflow step 3."""
    import requests  # not in starter set — defer to function body
    ...
    return df
```

Write sidecars via `host.skills.edit(name, "kernel.py", src)`. When the
gate probe can judge, the edit result carries `sidecar_gate: {ok, error?}`
— the same structural gate the load path runs — so a reject (non-literal
default, `_`-prefixed name, top-level call) surfaces immediately. When the
probe can't judge (interpreter unavailable, or the source doesn't parse
under the host's interpreter — possible version drift), the key is absent
and `note` says why. Iterate against that; don't load the skill just to
test the sidecar. `host.skills.publish` refuses only on a structural
reject.
