---
name: sysraptor
description: SysRaptor platform integration — push verified findings from the active activity folder into SysRaptor via its API, check push status, and keep the finding files' SysRaptor IDs in sync. Use when the user says sysraptor, push findings, upload findings, write findings into sysraptor, sync findings, or asks what still needs to be pushed.
---

# SysRaptor Integration

Findings live as Markdown files in `<activity>/findings/`; SysRaptor is the delivery platform. This skill moves verified findings into it — always with operator confirmation per finding batch.

## Configuration

- API key: `ONYX_SYSRAPTOR_API_KEY` environment variable, or a `sysraptor.local.json` file at the repo root (gitignored — never committed, never copied into an activity folder).
- Endpoints: **placeholder until the operator provides the API documentation.** The structure below is the contract; fill in methods/paths/field names once, then this skill is fully operational.

```
BASE_URL        = <pending operator>
AUTH            = <pending — header name + scheme>
CREATE_FINDING  = <pending — method + path>
UPDATE_FINDING  = <pending — method + path>
LIST_FINDINGS   = <pending — method + path (for dedupe/status checks)>
```

## Field mapping

The finding file format (see `report-writing`) maps onto SysRaptor fields. Confirm exact field names against the API docs when filling the endpoint map:

| Finding file | SysRaptor field |
|---|---|
| title line (F-NN — ...) | title |
| Severity | severity |
| CVSS 3.1 vector + score | cvss / score |
| Asset | asset / affected |
| Description | description |
| Steps to reproduce | steps / proof |
| Evidence | evidence (attachments if supported) |
| Impact | impact |
| Remediation | remediation |
| References | references |

## Workflow

1. **Inventory:** list `<activity>/findings/*.md` with their `SysRaptor:` status line — the push backlog is every file marked `not pushed`.
2. **Review:** show the operator the batch (IDs + titles + severities). Confirm exactly which findings go.
3. **Push one at a time:** create the finding, capture the returned ID, then immediately write it back into the finding file's `SysRaptor:` line (e.g. `pushed SR-1042`). A push without the ID written back is a lost link — never batch-write IDs at the end.
4. **Attachments:** evidence files (screenshots, captures) upload per API spec if supported; record attachment state in the finding file.
5. **Report sync:** the summary table in `<activity>/report/report.md` includes the SysRaptor IDs — the platform and the report always agree.

## Rules

- **Confirm before every push batch.** SysRaptor is an external system — the same finding pushed twice is worse than pushed once late; the status line is the source of truth for what's already there.
- The API key never appears in finding files, reports, notes, command output shown to third parties, or anything inside `projects/`.
- If an endpoint call fails, stop the batch, show the operator the raw error, and fix before retrying — partial batches with silent failures corrupt the sync.
- Until the endpoint map is filled in, this skill prepares findings for push (format check + batch review) and stops — say plainly that the API integration isn't configured yet.
