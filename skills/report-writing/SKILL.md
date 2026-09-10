---
name: report-writing
description: Writing penetration test findings and engagement deliverables — per-finding writeups with CVSS 3.1 severity, executive summary, full report structure, and export to Markdown or SysReptor via the sysreptor skill. Use when the user says write the report, write this finding, what severity is this, CVSS, executive summary, wrap up the engagement, or findings need to be delivered to the client.
---

# Report Writing

The report is the product the client actually pays for. A finding that isn't reproduced, or a writeup the customer's engineer can't replay in five minutes, is worth nothing. Doctrine: nothing gets written up that wasn't reproduced.

## Per-finding format

Findings live as `<activity>/findings/F-<NN>-<slug>.md`, written from `templates/finding.md` **during** testing. The format is SysReptor-aligned so pushing later is mechanical:

```markdown
# F-<NN> — <Vulnerability class> in <component> leads to <impact>
- Severity: <Critical/High/Medium/Low/Info>
- CVSS 3.1: <vector> (<score>)
- Asset: <exact host/URL/app/package>
- Status: open | fixed | risk-accepted
- SysReptor: <not pushed | pushed <id>>

## Description / Steps to reproduce / Evidence / Impact / Remediation / References
```

Writing rules:
- **Lead with impact.** The title is the finding: "IDOR in `/api/v1/invoices` exposes all customers' billing data" — not "Broken access control."
- **Repro steps are imperative and complete** — an engineer with no context reaches the same result. Include exact requests; parameterize test-account IDs.
- **CVSS is a justification, not a score generator** — give the vector; when business context outweighs the base score, say so in one line and rate accordingly.
- One report per vulnerability. Chains are one finding when the impact is the chain; separate primitives stay separate.
- Real customer data never appears in evidence — redact before it leaves the activity folder.

## Full engagement report structure

Written into `<activity>/report/report.md`:

1. **Executive summary** — 1 page, business language: what was tested, overall risk posture, the top 3 risks by business impact, what to fix first.
2. **Scope & methodology** — the scope card contents, testing window, phases run, tools used.
3. **Findings** — each in the per-finding format, ordered by severity, stable IDs (F-01, F-02...).
4. **Risk ratings summary table** — ID, title, severity, status, SysReptor ID — the remediation tracker.
5. **Appendix** — raw evidence, full request/response dumps, cleanup confirmation (accounts created, files staged and removed).

## Process

- Draft findings during testing; assemble the report at wrap-up (`engagement-setup` session-close flow).
- Severity calls the operator can defend: rate impact as demonstrated, not as theorized.
- **Before anything leaves the machine** — pushing to SysReptor, sending the report to the client, any other delivery: **ask the operator first.** Every time.
- After delivery: customer questions get answered with evidence, not assertions; re-verify anything asked to be re-demonstrated.
