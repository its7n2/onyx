---
name: service-enumeration
description: Deep port, service, and content enumeration for authorized hosts, external and internal — staged nmap workflow, version/script scanning, UDP, web content and vhost discovery with ffuf, and technology-specific enumeration (SMB, LDAP, SNMP, FTP, SSH, databases). Use when the user mentions nmap, port scanning, scanning a box, enumerating services, directory brute-forcing, ffuf, "what's running on this host", or follow-ups after recon finds live hosts.
---

# Service Enumeration

Turn the asset list into a service map with versions and entry points — works for external perimeters and internal subnets alike. Targets must already be in `scope.md`. All tooling runs on Kali.

## Staged nmap (fast → deep, never one giant scan first)

```bash
nmap -Pn -sV --top-ports 100 <host>
```
Then, informed by the first pass:
```bash
nmap -Pn -p- -sV -sC --open <host>
```
UDP after TCP (slow, be selective):
```bash
nmap -Pn -sU --top-ports 50 <host>
```

Internal subnets: sweep live hosts first (`nmap -sn <cidr>`), then stage the deep scans per host. A full-range scan first wastes the window and trips IDS. Follow version leads immediately — an exposed service version is a finding lead, not trivia.

## Web content discovery

- Directory/file fuzz: `ffuf -w /usr/share/seclists/Discovery/Web-Content/raft-medium-words.txt -u https://host/FUZZ -mc all -fc 404` — tune the wordlist to what recon fingerprinted (lowercase lists, extension fuzzing `-e php,asp,aspx,jsp,html,bak,old` for known stacks).
- Recursive digging only where it pays: `ffuf -recursion -recursion-depth 2`.
- Vhost fuzzing: `ffuf -w subdomains.txt -u https://<ip> -H "Host: FUZZ.example.com" -fs <default-size>`.
- Compare against a known-404 baseline size/response to filter noise (`-fs`, `-mr`).

## Service-specific follow-ups (version-dependent)

| Service | Next moves |
|---|---|
| SMB | `smbclient -L //host -N`, `enum4linux-ng -A`, `nmap --script smb-vuln*` — sign? null session? |
| LDAP | anonymous bind, `ldapsearch -x -b "" -s base`, rootDSE attrs — domain context goes to `internal-network` |
| SNMP | `snmpwalk -v2c -c public <host>` (try common community strings) |
| FTP | anonymous login, writable dirs, version exploits |
| Databases | default-cred checks (Mongo, Redis, Elasticsearch unauthenticated API), version-match via `searchsploit` |
| SSH | version/banner, weak-key and user-enumeration CVEs for the version |
| Mail (SMTP) | user enumeration (VRFY/EXPN), open relay test |
| RDP/WinRM | post-auth targets — flag for the cred-testing stage of `internal-network` |

## Output

Per host, write `<activity>/enum/<host>.md`: a service table (port, service, version, script output highlights), plus a "leads" section — anything version-matched to a public exploit, anything misconfigured, anything weird. Raw scans live in `enum/raw/`.

## Rules

- Version-match through `searchsploit` before getting excited; banner noise is common.
- Null sessions and default-credential checks are standard; credential *brute-forcing* and spraying happen only with explicit RoE coverage (`internal-network` handles that stage).
- On internal engagements, misconfig evidence (unlocked SMB shares, LDAP anon, SNMP strings) is finding material in itself — log it even before exploitation.
