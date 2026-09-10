---
name: webapp-testing
description: Web application security assessment for authorized pentest targets — full hands-on OWASP workflow covering IDOR/BAC, auth bypass, SSRF, SQLi and command injection, file upload, deserialization, XSS/CSRF, JWT and session flaws, and business-logic abuse. Use when the user says web app testing, test this site/app, test the login, look for vulnerabilities, mentions IDOR, SQLi, SSRF, XSS, JWT, or is running a webapp engagement.
---

# Web Application Testing

Walk the app like a user first, attack it like an engineer second. Never test a web app that isn't in `scope.md`. All tooling runs on Kali; proxy through Burp/ZAP.

## Phase 1 — Map the app

- Use it honestly: register accounts (throwaway, e.g. `onyx+<target>@...`), walk every feature, note role differences if multiple roles exist (register at least two accounts for BAC testing).
- Proxy everything, keep history. Map endpoints, parameters, client-side routes from JS bundles (pull and beautify the main bundles; grep for endpoints, keys, hidden params).
- Identify the stack (framework, template engine, API style) — it predicts bug classes.

## Phase 2 — Systematic testing matrix

Work category by category; note every parameter tested and the result, even negatives — the negative results close out the report later.

- **IDOR / BAC:** every object reference (IDs, UUIDs, filenames) gets tried from user B's session. Horizontal and vertical (regular user → admin endpoints). Highest-ROI class in web engagements — check every request you naturally make.
- **Auth:** register/login/reset flows — user enumeration via differential responses, reset-token predictability, account takeover chains, JWT issues (`alg: none`, weak HMAC secrets, `kid` injection, algorithm confusion RS256↔HS256).
- **SSRF:** every spot the server fetches a URL you control — webhooks, import/export, PDF generators, image-from-URL, profile picture via URL. Point at your collaborator/Burp Collaborator first; internal target checks after confirming RoE covers it.
- **Injection:** SQLi (error-based and boolean diffs first; `sqlmap` only on in-scope params, low-risk settings `--risk=1 --level=2`, never against production without explicit RoE coverage), command injection (file-name/backup/export features), template injection (SSTI probes like `${7*7}`), header injection.
- **File upload:** extension/content-type bypass, path traversal in filenames, upload-to-exec paths (webroots, buckets beside web roots).
- **Deserialization:** framework-telltale blobs (PHP `O:`, Java `AC ED`, .NET `AAEAA`), known gadget chains for the detected stack.
- **XSS/CSRF:** reflected/DOM (audit JS sinks: `innerHTML`, `eval`, `document.write`), stored (profile fields, names, anything rendered to others), CSRF on state-changing actions (token presence, SameSite).
- **Business logic:** price/quantity tampering, negative values, race conditions on limited actions (duplicate the request in parallel, don't DoS), workflow skipping (call step 3 directly), coupon/limit abuse.

## Phase 3 — Evidence

For every candidate finding, capture the exact request/response pair (raw, from proxy history) and a minimal repro. One finding = one file: `<activity>/findings/F-<NN>-<slug>.md` using `templates/finding.md` — written during testing, not after. Screenshots land in `evidence/`.

## Rules

- Two accounts minimum, one victim one attacker; never touch real users' data — if an IDOR exposes other users, grab one record as proof, note it, and stop (data-handling rule in `scope.md`).
- Report only what you reproduced — `report-writing` turns finding files into the deliverable, `sysreptor` pushes them (confirm first).
- Testing accounts and staged payloads get cleaned up or disclosed in the report — the customer should never discover test artifacts we didn't document.
