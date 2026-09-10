---
name: nuclei-hunting
description: Template-driven vulnerability scanning and custom template authoring with Nuclei — running safe in-scope sweeps (CVEs, exposures, misconfigs, panels), writing custom templates for client-specific patterns and fresh CVEs, and properly triaging hits into verified findings. Use when the user mentions nuclei, templates, CVE sweep, scanning assets for known vulns, exposed panels/misconfigs, writing a nuclei template, or turning a new CVE into a detection.
---

# Nuclei Hunting

Nuclei turns fingerprints into findings at scale — but a scanner is a magnifying glass, not a tester. Every hit gets manually verified; the real edge is authoring templates for patterns nobody else scans for.

## Safe operation (non-negotiable)

- Only against assets in the scope card. No "quick checks" of neighbors.
- Rate-limit and concurrency: `-rl 10 -c 25` as a courtesy default, tighter if the RoE says so.
- Exclude destructive/slow tags: `-tags exclude dos,fuzz,brute-force` — never run brute-force or DoS-class templates against client targets.
- `nuclei -update-templates` before each session; stale templates = stale results.

## The sweeps, in order of ROI

```bash
# 1. Tech-matched CVE sweep (fingerprint from recon decides -tags)
nuclei -l <activity>/recon/live.txt -tags cve -severity medium,high,critical -rl 10

# 2. Exposures & misconfigs
nuclei -l <activity>/recon/live.txt -tags exposure,misconfig -rl 10

# 3. Panels & takeovers
nuclei -l <activity>/recon/live.txt -tags panel,takeover -rl 10
```

Tag first (`-tags cve`), severity second — a template's tags describe where it lives; `-tags` + a matched tech filter (`-tech-detect` output feeding a filtered list) beats blind full-template runs. Feed it the resolved-live host list from `recon`, not raw subdomains.

## Custom template authoring — the actual edge

Client-specific knowledge becomes reusable detection. Skeleton:

```yaml
id: clientname-debug-endpoint

info:
  name: Customer Debug Mode Exposure
  author: onyx
  severity: medium
  description: Internal debug endpoint exposed on production hosts.
  reference:
    - https://example.com/policy
  tags: clientname,exposure,detect

http:
  - method: GET
    path:
      - "{{BaseURL}}/__internal/status"
    matchers-condition: and
    matchers:
      - type: word
        part: body
        words:
          - "debug_enabled"
      - type: status
        status:
          - 200
    extractors:
      - type: regex
        name: version
        regex:
          - '"version":"([^"]+)"'
```

Authoring rules:

- **Matchers must be unambiguous:** pair a body word with a status (and a header if available). One loose body word = false positives = triage noise you created.
- **Detect vs. verify:** `severity: info` + `tags: detect` for fingerprinting templates; verification templates (the ones that prove impact) earn real severity and belong in `nuclei-custom/verified/`.
- Sources of custom templates: the customer's own JS (endpoint paths unique to their stack — mined in `recon`/`webapp-testing`), response quirks noticed manually, and **fresh CVEs you root-caused**: turn the patched check into a matcher and you have a scanner before public templates ship — that's first-mover advantage across the customer's whole estate.
- Keep `nuclei-custom/` versioned outside `projects/` (reusable across customers only with client-identifying patterns scrubbed); a template that hits gets copied into the activity dir as evidence.

## Triage — every hit, every time

1. Re-request the exact URL manually; confirm the matcher content in the raw response.
2. Assess: is it a real exposure, a staging host leaking prod strings, or a false positive (common with generic word matchers on error pages)?
3. Real → evidence capture (request/response pair) → `findings/` per `report-writing`. Unverified scanner output never becomes a finding.
4. Recurring FP → fix your template (tighten matchers) or delete it; noise compounds against you.

## Rules

- Templates that change state (login, submit, delete anything) are exploit steps, not scanning — run those manually, one target at a time, with the RoE in hand.
- CVE-sweep results on third-party-shared infrastructure (CDN nodes, SaaS) get scope-checked before anyone celebrates.
