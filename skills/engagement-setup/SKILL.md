---
name: engagement-setup
description: Engagement and project management for penetration testing — create or open a customer project, add a new activity (external/internal network, webapp, api, mobile), capture scope and rules of engagement, and route to the right phase skill. Use at the start of every session or whenever the user mentions a new engagement, new customer, new activity, project setup, kickoff, scoping a pentest, or names a client to work for.
---

# Engagement Setup — Kickoff Router

Every engagement lives in a project folder. Every activity lives inside it. Nothing gets tested until scope and RoE are on disk and confirmed. This skill is the gate every session passes through.

## Paths

- Projects root: `projects/` at the onyx repo root.
- Customer folder: `projects/<customer-slug>/` — slug is lowercase hyphenated (`Acme Corp` → `acme-corp`).
- Activity folder: `projects/<customer-slug>/<YYYY-MM-DD>_<activity-type>/` — activity type is one of `external-network`, `internal-network`, `webapp`, `api`, `mobile`, or a hyphenated combo (`webapp-api`). Same day + same type → suffix `-2`, `-3`.
- Templates live in `templates/` at the repo root — copy them, never hand-format.

## Workflow

**1. Identify the customer.** Ask the operator for the customer name. Check `projects/` for a matching slug.

**2. New customer** → create the folder and write `profile.md` from `templates/profile.md`. Minimum to fill now: customer name, creation date, contacts if known. History fills in as engagements happen.

**3. Existing customer** → read `profile.md`, list past activities with dates/status from the history table, confirm this is the right customer. Add the new activity; never reopen a closed activity folder for new testing.

**4. Capture the activity.** Ask activity type (and confirm any combo). Create the activity folder with the full layout:

```
scope.md  roe.md  recon/  enum/  findings/  evidence/  notes.md  report/
```

**5. Scope + RoE intake.** Fill `templates/scope.md` and `templates/roe.md` from what the operator provides. Cover at minimum:
- Asset list (IP ranges, hosts, URLs, app names, package names/bundle IDs) — in-scope table with explicit entries.
- Explicit out-of-scope list.
- Testing window, prohibited techniques, rate limits.
- Credentials provided (which system/account — never the secrets themselves).
- Escalation contacts + crash/incident policy.
- **Flag every ambiguity** (shared hosting, CDN-hosted assets, wildcard ranges, staging vs prod, third-party SaaS on customer domains) and get an explicit in/out decision recorded in `scope.md`.

**6. Confirm the gate.** Show the operator `scope.md` + `roe.md` summaries. Testing starts only after explicit operator confirmation. Any later scope change → update the file first, re-confirm, then test.

**7. Update `profile.md`** — add the activity row to engagement history with status `active`.

**8. Route** to the phase skill for the activity type and state which skill you're routing to:

| Activity type | First phase skill |
|---|---|
| external-network | `recon` → `service-enumeration` |
| internal-network | `service-enumeration` → `internal-network` |
| webapp | `webapp-testing` |
| api | `api-testing` |
| mobile | `mobile-testing` |

## Session close (whenever wrapping up)

- Update `notes.md` (state of testing, pending leads) and the activity status in `profile.md`: `active` → `testing-done` → `reported`.
- If findings exist and the operator wants to report: `report-writing` → `sysreptor` (confirm before any push).

## Rules

- The kickoff gate is absolute: **no testing of any kind before `scope.md` + `roe.md` exist and the operator confirmed them.** If the operator asks to skip scoping, surface the risk and refuse until the files exist.
- One customer = one folder, forever. Activities accumulate; history is the memory.
- Customer data stays inside `projects/` — it's gitignored and never leaves the machine without the operator's explicit action.
- Dates in folder names are the activity start date, not today's date once work spans days.
