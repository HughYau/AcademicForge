---
name: using-model-endpoint
description: Call a registered model endpoint over its native HTTP API from the endpoint's scoped inference kernel (BASE_URL preloaded). Load once a task needs predictions from a registered model endpoint.
license: Apache-2.0
---

You are a **pure HTTP client of `BASE_URL`**. Each registered model endpoint
gets its own inference kernel — a Python REPL whose network egress is scoped
to exactly that endpoint — reached via
`compute_provider({'provider': '<slug>', 'code': '…'})` (`<slug>` from
`list_compute`, without the `infer:` prefix).

- `BASE_URL` is preloaded (as a Python variable AND as
  `os.environ["BASE_URL"]`) — build request URLs from it, never hardcode
  hosts/ports. Call the model's **native API** with `httpx` (preinstalled)
  or `requests`; request shapes live in the provider's own runbook skill
  (the registration's `skillName`).
- Hosted endpoints: send `Authorization: Bearer $INFER_API_KEY` (always the
  canonical env name when a credential is delivered; the credential's own
  name is usually aliased too). Local endpoints need no auth header.
- Requests ride the sandbox HTTP proxy (`HTTP_PROXY`/`HTTPS_PROXY` are set) —
  don't disable it (e.g. `trust_env=False`) or the endpoint is unreachable.
- No job lifecycle here (no submit/harvest) — direct request/response only.

**Managed endpoints** (entries with `managed: true` / a `location` field in
`list_compute`): their lifecycle — daemon-owned start/stop, registration,
`free_port()`/`register()` — lives in the
**`managed-model-endpoints`** skill. Cells against them are still just
HTTP calls to `BASE_URL`; the daemon brings the model up on demand (a cold
start streams its progress into your cell and can take minutes).
