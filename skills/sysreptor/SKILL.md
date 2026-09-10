---
name: sysreptor
description: SysReptor platform integration — push verified findings from the active activity folder into SysReptor via its REST API, keep finding files' SysReptor IDs in sync, run report checks and generate/export the report. Use when the user says sysreptor, push findings, upload findings, write findings into sysreptor, sync findings, generate report PDF, or asks what still needs to be pushed.
---

# SysReptor Integration

Findings live as Markdown files in `<activity>/findings/`; SysReptor is the delivery platform. This skill moves verified findings into it — always with operator confirmation per push batch.

## Configuration

- Local config: `sysreptor.local.json` at the repo root (**gitignored** — never committed, never copied into an activity folder), or `ONYX_SYSREPTOR_API_KEY` env var (base URL defaults to `https://cloud.sysreptor.com` if only the env var is set).
- Self-hosted instance → change `base_url` in the local config.
- Load it:

```bash
BASE_URL=$(jq -r .base_url sysreptor.local.json)
AUTH="Authorization: Bearer $(jq -r .api_token sysreptor.local.json)"
```

No `jq` on the box? sed fallback:

```bash
BASE_URL=$(sed -n 's/.*"base_url": *"\([^"]*\)".*/\1/p' sysreptor.local.json)
AUTH="Authorization: Bearer $(sed -n 's/.*"api_token": *"\([^"]*\)".*/\1/p' sysreptor.local.json)"
```

## API map (per docs.sysreptor.com)

| Action | Call |
|---|---|
| Find the project | `GET {BASE}/api/v1/pentestprojects/?search=<customer>` |
| List project findings | `GET {BASE}/api/v1/pentestprojects/{project_id}/findings/` |
| Create finding (manual) | `POST {BASE}/api/v1/pentestprojects/{project_id}/findings/` |
| Create from finding template | `POST {BASE}/api/v1/pentestprojects/{project_id}/findings/fromtemplate/` — `{"template": "<template-id>"}` |
| Update finding | `PATCH {BASE}/api/v1/pentestprojects/{project_id}/findings/{finding_id}/` |
| Delete finding | `DELETE {BASE}/api/v1/pentestprojects/{project_id}/findings/{finding_id}/` |
| Report quality checks | `GET {BASE}/api/v1/pentestprojects/{project_id}/check` |
| Generate report PDF | `POST {BASE}/api/v1/pentestprojects/{project_id}/generate/` |
| Export project archive | `POST {BASE}/api/v1/pentestprojects/{project_id}/export/` — `{"export_all": true}` |

Severity values: `critical` | `high` | `medium` | `low` | `none` (map Info → `none` unless the project's design defines an `info` choice).

## Field mapping

Finding file (see `report-writing`) → SysReptor. `title`, `severity`, `description` are standard; everything else is a design field — confirm exact names against the project design (GET an existing finding or the project design) before the first push:

| Finding file | SysReptor field |
|---|---|
| title line (F-NN — ...) | title |
| Severity | severity |
| CVSS 3.1 vector + score | cvss (design field: vector + score) |
| Asset | affected |
| Description | description |
| Steps to reproduce | steps / merged into description per design |
| Impact | impact |
| Remediation | recommendation |
| References | references |

## Workflow

1. **Inventory:** list `<activity>/findings/*.md` with their `SysReptor:` status line — the push backlog is every file marked `not pushed`.
2. **Review:** show the operator the batch (IDs + titles + severities). Confirm exactly which findings go.
3. **Locate the project:** search by customer name, show matches, operator confirms the project ID. Project *creation* only happens on explicit operator instruction (it needs a `project_type` design ID from the instance).
4. **Push one at a time:**

```bash
curl -s -X POST "$BASE_URL/api/v1/pentestprojects/$PROJECT_ID/findings/" \
  -H "$AUTH" -H "Content-Type: application/json" \
  -d '{"title": "SQL Injection in login", "severity": "high", "description": "...", "cvss": "CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H", "affected": "https://target/login", "impact": "...", "recommendation": "...", "references": "..."}'
```

   Capture the returned finding ID and **immediately** write it back into the finding file's `SysReptor:` line (e.g. `pushed <id>`). A push without the ID written back is a lost link — never batch-write IDs at the end.
5. **Verify:** run the `/check` endpoint and fix reported issues before generating; `generate/` only on operator request — the PDF lives in `report/`.

## Rules

- **Confirm before every push batch.** SysReptor is an external system — the same finding pushed twice is worse than pushed once late; the finding file's status line is the source of truth for what's already there.
- The API token never appears in finding files, reports, notes, anything inside `projects/`, or command output shown to third parties.
- If an API call fails, stop the batch, show the operator the raw error, fix before retrying — partial batches with silent failures corrupt the sync.
- Prefer `fromtemplate/` when the instance has a matching finding template — design fields then come pre-filled; PATCH the specifics after.
