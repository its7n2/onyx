---
name: internal-network
description: Internal network and Active Directory penetration testing — host discovery and enumeration, credential collection and spraying, Kerberoasting and AS-REP roasting, BloodHound path analysis, lateral movement, relaying, and domain dominance. Use when the user says internal network, internal pentest, Active Directory, AD, domain, lateral movement, Kerberoast, BloodHound, netexec, secretsdump, or is on an internal-network engagement with a foothold or LAN access.
---

# Internal Network & Active Directory

Internal engagements are a progression: see the network → get credentials → get a domain account → own the domain. Every stage writes evidence; every escalation technique runs only with RoE coverage. All tooling runs on Kali (`netexec`/`nxc`, impacket, BloodHound).

## Stage 1 — Situational awareness

- Own IP, interfaces, routes (`ip a`, `ip r`); DNS server = likely DC; `getent hosts <domain>` or dig SRV records: `_ldap._tcp.dc._msdcs.<domain>`.
- Host discovery: `nmap -sn <cidr>` → live list into `<activity>/enum/`. Deep-dive hosts via `service-enumeration`.
- No foothold yet? Passive-first:Responder off by default — ask the operator; Responder/`mitm6` are loud and need RoE coverage.

## Stage 2 — Credential collection

- **Null sessions / anon:** `nxc smb <dc> -u '' -p ''`, `enum4linux-ng -A`, LDAP anonymous → user lists.
- **AS-REP roastable:** `GetNPUsers.py <domain>/ -usersfile users.txt` — hash → crack offline (`hashcat -m 18200`).
- **Kerberoasting:** `GetUserSPNs.py <domain>/<user>:<pass> -request` → `hashcat -m 13100`. Service accounts with weak passwords are the classic way in.
- **Shares:** `nxc smb <range> -u <user> -p <pass> --shares` — readable/writable shares, hunt configs, scripts, creds in files (grep for `password`, `connect`, config extensions).
- **Loot discipline:** everything found → `<activity>/evidence/loot.md` (system + account + how obtained). Cracking happens on the operator's hardware; plaintext secrets stay out of synced files.

## Stage 3 — Credential spraying & access

- RoE check first: spraying locks accounts. Confirm lockout policy (`nxc smb <dc> -u '' -p '' --pass-pol`) and get operator sign-off on the target list.
- `nxc smb <targets> -u users.txt -p 'Season!2026' --continue-on-success` — one password, many users, low-and-slow. Stop at the first valid hit and pivot to targeted use.
- Validate access: `nxc smb <host> -u <user> -p <pass>` → enumerate what the account can reach (sessions, disks, users, groups).

## Stage 4 — Path analysis (BloodHound)

```bash
bloodhound-python -u <user> -p <pass> -d <domain> -dc <dc> -c All
```
Analyze the shortest paths: Kerberoastable → DA, DCSync rights, gMSA readable, unconstrained delegation, session hops (DA logged in where?). Record the chosen path in `notes.md` — the report needs the chain, not just the endpoint.

## Stage 5 — Lateral movement & escalation

Technique per hop, RoE-checked, one at a time:
- **psexec / atexec / wmiexec / smbexec** (impacket) — svc-ctl creds or local admin.
- **WinRM:** `nxc winrm <host> -u <user> -p <pass>` / Evil-WinRM — interactive.
- **Relay:** `ntlmrelayx.py -tf targets.txt` — only with explicit RoE coverage, SMB signing off confirmed; signing on = relay dead, note it as a positive control finding.
- **RDP** where interactive work pays; restricted-admin mode noted.
- Each hop: verify (`whoami`, hostname), document vector + proof in `enum/<host>-access.md`.

## Stage 6 — Domain dominance (with operator confirmation)

- **DCSync:** `secretsdump.py <domain>/<user>@<dc>` — dump NTDS if the path grants Replication rights. All DA hashes → `loot.md` (hashes only).
- Golden/silver ticket demonstrations only if the RoE explicitly allows — a flag on the domain is a finding, not a trophy; demonstrate minimal effect and stop.
- Persistence mechanisms: never deployed on client engagements unless the RoE demands proof of resilience — then documented, time-boxed, and removed with evidence.

## Stage 7 — Wrap-up

- Cleanup list: sessions, staged tools, added accounts (if any), Responder/relay listeners killed — recorded in `notes.md` and confirmed in the report appendix.
- Findings → `findings/` per `report-writing` (each stage failure/misconfig above is finding material: password policy, SMB signing, share permissions, Kerberoastable service accounts).

## Rules

- **Spraying, relaying, and domain dominance need explicit RoE coverage + operator confirmation at that stage** — not blanket "pentest approved" hand-waving.
- Account lockouts: stop spraying immediately, note affected accounts, notify the escalation contact per `roe.md`.
- Production services stay up; one controlled technique at a time, never a shotgun across the subnet.
- Hashes and cracked passwords stay in the operator's local cracking environment; the activity folder records system/account/have-hash flags, not plaintext secrets.
