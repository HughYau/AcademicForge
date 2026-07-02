---
name: self-awareness
description: Claude Science's own session database schema and SDK surface for introspection via host.query(). Load this when you need to query your own conversation history, token usage, cost accounting, execution log, or artifact metadata beyond what host.frames()/host.artifacts() provide — e.g. "how many tokens has this session used", "what was my last tool call", "list every file I've written", "where are messages stored", "what tables can I query", "inspect frames.context_data", or any time you're about to PRAGMA-probe the Claude Science metadata DB to discover its schema.
license: Apache-2.0
---

# Self-awareness — Claude Science's own database and SDK

`host.query(sql, params=[], limit=None, df=False)` runs read-only SQLite
against Claude Science's own metadata DB. It is only available via the **`repl`
tool** (not `python`/`r`). Results are automatically scoped to the current
project, so `SELECT * FROM frames` returns only frames in this project. The
`repl` tool is stdlib-only — `df=True` returns the raw dict there (use
`json.dump(..., open("handoff/q.json","w"))` and load in a `python` cell if
you want pandas).

## Dialect and limits

- **SQLite.** Epoch-milliseconds for all timestamps
  (`created_at > strftime('%s','now','-1 day')*1000`). Booleans are `0`/`1`.
  JSON columns are TEXT — use `json_extract(col, '$.key')`. Recursive CTEs OK.
- `SELECT` / `WITH` / `PRAGMA` / `EXPLAIN` only; one statement per call;
  `?` placeholders with `params=[...]`.
- **Scoping.** Most tables are transparently filtered to the current
  project (and `memories` to the current user) via CTEs that shadow the
  real tables — `session_claims`, `verification_checks`, and `poller_lease`
  are unscoped. You therefore **cannot** use `main.table` / `temp.table` —
  schema-qualified names are rejected.
- **Caps.** Default 200 rows (max `limit=1000`); cells >2000 chars are
  clipped in place with a `…[+N chars]` marker; total serialized output
  capped at ~100k chars (`truncated=True`, `truncation_reason="total_size_cap"`
  — narrow your columns). 5-second timeout.
- Schema introspection: `host.query("PRAGMA table_info(frames)")` or
  `host.query("SELECT name, sql FROM sqlite_master WHERE type='table'")`.

## Queryable tables

### Session / conversation

**`frames`** — one row per agent frame (a root conversation or a delegated
sub-agent). The frame you are running in now is one of these rows.
Key columns: `id`, `parent_frame_id`, `root_frame_id`, `agent_name`,
`delegate_name`, `status` (`processing`/`completed`/`failed`/`cancelled`/
`awaiting_user_response`/`awaiting_plan_approval`), `model`, `effort`, `input_tokens`,
`output_tokens`, `cache_read_tokens`, `cache_write_tokens`, `total_cost`,
`task_summary`, `status_description`, `conversation_type`, `name`,
`project_id`, `created_at`, `updated_at`, `completed_at`,
`last_user_message_at`, `is_hidden`.
JSON columns: `input_data` (what started the frame), `output_data`
(`json_extract(output_data,'$.response')` is the final response text),
`context_data` (the full serialized runner state — see below),
`mentioned_artifact_ids`, `specialists_used`.

`context_data` is large. It holds the entire runner state under
underscore-prefixed keys — notably `$._messages` (the full conversation
array), `$._input_tokens` / `$._output_tokens` / `$._total_cost` (same values
as the top-level columns), `$._running_children`, `$._plan_json`,
`$._compaction_count`, `$._tool_id_to_frame_id`. Selecting it raw will hit
the cell cap; use `json_extract`/`json_array_length` to read specific keys.
For the messages themselves, prefer `host.frames(frame_id=...)` which
paginates — `_messages` via SQL will truncate on any non-trivial session.

**`compaction_archives`** — pre-compaction message snapshots.
`frame_id`, `compaction_index`, `message_count`, `token_count`, `summary`,
`messages` (JSON array), `created_at`. When a frame's `_compaction_count > 0`,
the original messages that were summarized live here.

**`notifications`** — parent↔child messages. `sender_frame_id`,
`recipient_frame_id`, `root_frame_id`, `notification_type`, `payload` (JSON),
`read_at`, `created_at`.

**`projects`** — `id` (`proj_*`, not a UUID), `name`, `description`,
`context`, `user_id`, `uploads_frame_id`, `memory_enabled`, `created_at`,
`updated_at`.

**`notes`** — user annotations. `project_id`, `target_type`,
`target_frame_id`, `target_message_index`, `target_artifact_id`, `content`.

### Artifacts

**`artifacts`** — one row per file. `id`, `project_id`, `root_frame_id`,
`frame_id`, `filename`, `latest_version_id`, `is_user_upload`, `is_ephemeral`,
`folder_id`, `sort_order`, `priority`, `created_at`.

**`artifact_versions`** — one row per saved revision. `id`, `artifact_id`,
`version_number`, `frame_id`, `content_type`, `size_bytes`, `checksum`,
`storage_path`, `extracted_code`, `code_description`, `language`,
`agent_name`, `is_intermediate`, `is_checkpoint`, `parent_version_id`,
`producing_cell_id` (→ `execution_log.id`), `created_at`. JSON:
`lineage_messages`, `dependency_mappings`, `environment_snapshot`,
`annotations`, `cell_sources`. Join `artifacts.latest_version_id =
artifact_versions.id` for size/type.

**`artifact_dependencies`** — DAG edges. `artifact_version_id`,
`depends_on_version_id`, `reference_name`.

**`artifact_folders`** — `id`, `project_id`, `parent_id`, `name`,
`root_frame_id`, `is_conversation_folder`, `is_user_uploads_folder`,
`sort_order`.

**`content_snapshots`** — content-addressed dedup store. `hash`, `content`,
`size_bytes`. Referenced by `artifact_versions.lineage_snapshot_hash` /
`env_snapshot_hash`.

### Execution history

**`execution_log`** — one row per `python`/`r`/`bash`/`repl` cell, in
order. `id`, `frame_id`, `cell_index` (monotonic), `kernel_id`, `kernel_kind`
(`analysis`/`operon`), `conda_env`,
`language`, `source` (exact submitted
code), `stdout`, `stderr`, `exit_status` (`ok`/`error`/`kernel_died`/
`cancelled`), `error_lineno`, `files_written` (JSON `[{path, sha256}]`),
`created_at`. This is the ground-truth record of everything you've run.

**`host_call_log`** — one row per `host.*` SDK call made inside a cell.
`id`, `execution_log_id` (→ `execution_log.id`), `seq`, `method`
(`query_db`/`llm`/`mcp`/`list_frames`/…), `args_json`, `derivable`,
`data_inline`, `data_ref`, `error`, `bytes`, `created_at`. Ordered by
`(execution_log_id, seq)`.

### Compute and verification

**`compute_usage`** — remote compute jobs. `job_id`, `environment`,
`tier_type` (`gpu`/`cpu`), `provider`, `frame_id`, `project_id`, `started_at`,
`ended_at` (null ⇒ running), `expires_at`, `state`, `remote_workdir`,
`submit_cell_id`. JSON: `output_specs`, `remote_handle`.

**`session_claims`** — falsifiable claims extracted for verification.
`root_frame_id`, `frame_id`, `step_id`, `claim_text`, `entities` (JSON),
`source` (`agent`/`haiku_extracted`).

**`verification_checks`** — reviewer verdicts. `root_frame_id`,
`artifact_version_id`, `claim_id`, `claim`, `verdict`
(`pass`/`warn`/`fail`/`inconclusive`), `severity`, `evidence`, `rebuttal`,
`reviewer_model`, `reviewer_frame_id`, `source_ref` (JSON), `status`
(`open`/`resolved`/`unaddressed`), `reflag_count`.

**`memories`** — durable beliefs (user-scoped; may be absent on some builds).
`id` (`mem_*`), `body`, `subject_project_id`, `subject_artifact_id`,
`subject_version_id`, `subject_frame_id`, `source_frame_id`, `origin`
(`extractor`/`agent_tool`/`user`), `evidence`
(`stated`/`observed`/`inferred`), `superseded_by`, `last_surfaced_at`.

**`poller_lease`** — single-writer guard for compute polling. `provider`,
`holder`, `expires_at`.

## Denied tables

These are rejected with `Table '<name>' is not queryable` — use the listed
SDK accessor instead.

- Secrets (encrypted at rest, blocked defense-in-depth): `oauth_tokens`,
  `user_secrets`, `anthropic_api_keys`, `cloud_credentials`. →
  `host.credentials.list()` for non-secret metadata; `.get(name)` for
  the decrypted fields — usable in client libraries, redacted only from
  printed cell output.
- Agent/skill/connector configuration (enumerating attack surface has no
  legitimate raw-SQL use): `user_agents`, `agents`, `custom_agent_prompts`,
  `bundled_agent_settings`, `capability_settings`, `custom_skills`,
  `agent_skill_assignments`, `custom_mcp_servers`, `mcp_agent_assignments`,
  `mcp_tool_grants`, `directory_attachments`. → `host.agents.list()` /
  `host.skills.list()` / `host.agents.list_connectors()` (load the
  `customize` skill for that API).
- Host filesystem mounts: `host_grants`. → the `list_host_grants` tool
  (present on sandboxed-network builds).
- Compute provider configuration: `compute_providers`. → the
  `list_compute` / `compute_details` tools.

The denylist matches on word boundaries anywhere in the SQL, so a column
alias or string literal that happens to equal a denied table name will also
be rejected.

Host identity (hostname, workspace/pod name) is intentionally not exposed
anywhere in this DB (and on Linux builds the sandbox masks it as well) — to
know where you're running, ask the user or use `list_compute` labels.

## Worked examples

All of these run via the `repl` tool.

```python
# Token and cost accounting across every frame in THIS PROJECT (all
# sessions). Add `WHERE root_frame_id = ?` with the current root's id to
# scope to one session tree. Aggregate server-side so the row cap can't
# undercount.
r = host.query("""
  SELECT COUNT(*)                   AS n_frames,
         SUM(input_tokens)          AS input_tokens,
         SUM(output_tokens)         AS output_tokens,
         SUM(cache_read_tokens)     AS cache_read_tokens,
         SUM(cache_write_tokens)    AS cache_write_tokens,
         SUM(total_cost)            AS total_cost
  FROM frames
""")
n, itok, otok, crd, cwr, cost = r["rows"][0]
print(f"{n} frames, ${cost or 0:.4f} total")
```

```python
# Last 10 code cells executed in this project (any frame), with outcome.
# Add `WHERE e.frame_id = ?` with the current frame's id to scope to one
# frame.
host.query("""
  SELECT e.frame_id, e.cell_index, e.language, e.kernel_kind, e.conda_env,
         e.exit_status, substr(e.source, 1, 120) AS src,
         json_array_length(e.files_written) AS n_files
  FROM execution_log e
  ORDER BY e.created_at DESC
  LIMIT 10
""")
```

```python
# How far into context is each root conversation in this project? Reads
# _messages length and compaction count without pulling the whole blob.
host.query("""
  SELECT id, name,
         json_array_length(context_data, '$._messages')   AS n_messages,
         json_extract(context_data, '$._compaction_count') AS compactions,
         input_tokens, output_tokens
  FROM frames
  WHERE parent_frame_id IS NULL
  ORDER BY updated_at DESC
""")
```

```python
# Every artifact this project has, with current size/type, newest first.
host.query("""
  SELECT a.filename, v.content_type, v.size_bytes, v.version_number,
         a.is_user_upload, a.latest_version_id
  FROM artifacts a
  JOIN artifact_versions v ON a.latest_version_id = v.id
  WHERE a.is_ephemeral = 0
  ORDER BY v.created_at DESC
""")
```

## SDK surface — which tool runs what

The `host` object is a Python SDK backed by host-side RPCs. Run
`help(host)` / `help(host.<x>)` for signatures.

| Accessor | Tool | Returns |
|---|---|---|
| `host.query(sql, params, limit, df)` | **`repl`** | Raw SQL over the tables above |
| `host.frames(...)` | **`repl`** | List/search/detail frames (paginated messages) |
| `host.children()` | **`repl`** | Live sub-agents (delegation-enabled profiles only) |
| `host.delegate(task_or_list, name=?, profile=?, output_schema=?, model=?)` | **`repl`** | Spawn child agent(s), block until done (ultra-mode roots; requires `[delegation] sdk_enabled`). `model=` pins the child's model per request — e.g. a haiku-class id for cheap fan-outs. Blocks the cell — for long-running children run it in a background cell (a user message mid-call backgrounds it; a Stop / cell interrupt cancels the children) |
| `host.agents.*` / `host.skills.*` | **`repl`** | Profile and skill CRUD — load `customize` skill |
| `host.submit_output(output, completion_bullets=[...])` | **`repl`** | Submit your structured result when your task carries an OUTPUT SCHEMA section (required before completing). Build the dict in-kernel — the payload rides the host-call wire, not your prose; on a validation/review bounce, mutate the dict in memory and resubmit (replaces the recorded output) |
| `host.compute.*` | **`repl`** | Remote job submit/wait — load the compute skill it names |
| `host.artifacts(...)` | `python` | Filtered artifact search (wraps the join above) |
| `host.artifact_path(vid)` / `host.artifact_marker(vid)` | `python` | Resolve a version_id to a readable path / marker |
| `host.lineage[vid]` | `python` | `{code, messages, env, inputs}` for one version |
| `host.llm(prompt_or_list, model=?, ...)` | `python` | Single-turn completion via the host's API client. Omitting `model=` uses the Haiku-class kernel default (via `[llm] kernel_default_model`); for harder reasoning pass `model=host.reasoning_model()` (the Sonnet-class reasoning default via `[llm] kernel_reasoning_model`); `model=host.current_model()` only when the task needs your session's own model level — never hardcode a literal model id (they go stale) |
| `host.credentials.list()` / `.get(name)` | `python` | User-configured credential metadata |
| `host.mcp(server, method, **kw)` | **`repl`** | MCP/connector call — only exists in the `repl` tool; pass results to `python`/`r` via `./handoff/*.json` |

The `repl` tool and the `python` tool are separate processes that share
only the workspace directory — move data between them via
`./handoff/*.json`, not variables.
