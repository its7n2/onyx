---
name: recon
description: External reconnaissance and attack-surface mapping for authorized pentest targets — passive and active subdomain enumeration, asset discovery, technology fingerprinting, port sweeping, and OSINT. Use when the user says recon, reconnaissance, subdomains, attack surface, asset discovery, OSINT, fingerprinting, enumerate domains, or is starting an external-network engagement.
---

# Recon — External Attack Surface Mapping

Phase 1 of an external-network engagement. Goal: a complete, deduplicated inventory of what the customer exposes, so later phases test real assets instead of guesses. Requires a confirmed scope card (see `pentest-scope`) — every command below runs only against in-scope assets. All tooling runs on Kali.

## Workflow — passive first, then active

**1. Passive enumeration (no packets at the target):**
- Certificate transparency: `crt.sh`, `censys`, `certspotter` for subdomains.
- Subdomain tools: `subfinder -d example.com`, `amass enum -passive -d example.com`.
- Archive/history: Wayback Machine (`waybackurls`) for old endpoints and parameters.
- Code search for the customer's public repos: exposed keys, internal hostnames, endpoints.
- Expand the net: WHOIS/ASN lookups for IP ranges the customer owns, acquisitions list.

**2. Active enumeration:**
- DNS brute + permutations: `puredns brute`, `amass enum -active`, permutation tools (`gotator`, `dnsgen`).
- Resolve and probe: `dnsx` for resolution, `httpx` for live web services (status, title, tech, CDN).
- Port sweep the in-scope IPs: `nmap -sS -Pn --top-ports 1000` first pass; deeper ports go to the `service-enumeration` phase.

**3. Triage:**
- Screenshot everything: `gowitness` or `httpx -screenshot` — eyeball for login panels, admin interfaces, staging labels ("dev", "staging", "uat", "test").
- Exposed-panel and known-CVE sweep with `nuclei` (see `nuclei-hunting`) — safe tags only.

**4. Output:** write `<activity>/recon/assets.md` with an inventory table:

```markdown
| Host | IP | Ports | Tech | Status | Notes |
|---|---|---|---|---|---|
```

Raw tool output goes under `recon/raw/` — never delete it; dedupe happens in the table, not by discarding evidence.

## Rules

- Respect the RoE's rate limits and window — throttle active tools (`-rate-limit`, `-rl`); engagements aren't a race.
- Anything resolving outside the customer's infrastructure (shared hosting, third-party SaaS) gets flagged in the table and excluded until scope-checked (`pentest-scope`).
- Recon never ends: new assets appearing mid-engagement get scope-checked before testing.
- Feeds `service-enumeration` (deep dives) and `report-writing` (scope & methodology section).
