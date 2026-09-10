---
name: privesc
description: Privilege escalation on authorized compromised hosts — Linux and Windows. Systematic post-exploitation enumeration (sudo, SUID, services, scheduled tasks, credentials, kernel exploits, AD quick wins) and turning misconfigurations into root/SYSTEM. Use when the user says privesc, privilege escalation, has a low-priv shell/foothold, wants escalation paths, or asks what to do after getting a shell on a box.
---

# Privilege Escalation

You have a foothold; the job is root/SYSTEM — methodically, without crashing the box. Foothold implies the host is in scope and the RoE covers post-exploitation; if that's not certain, stop and check the scope card. All tooling runs on Kali.

## Step 0 — Situational awareness

Record first: whoami / id, hostname, OS version + patch level, shell quality (TTY? upgrade if not), network position, how you got here (the foothold matters — its logs, its stability). Write into `<activity>/enum/<host>.md` as you go; a privesc session without notes repeats itself.

## Linux enumeration checklist

Work top to bottom; each hit gets followed immediately:

- `sudo -l` — any NOPASSWD entry; GTFOBins for allowed binaries.
- SUID/SGID: `find / -perm -4000 -type f 2>/dev/null` → GTFOBins matches.
- Capabilities: `getcap -r / 2>/dev/null` (cap_setuid, cap_dac_override...).
- Cron: system + user crontabs, **writable targets and writable directories in PATH of root-run scripts**.
- Services: writable service files/units, world-writable configs that a privileged process reads.
- Credentials: configs, history files (`~/.bash_history`), scripts with passwords, `/var/backups`, source trees, environment files.
- Containers/agents: Docker group (root via socket), Kubernetes serviceaccount tokens, backup agents.
- Kernel: version → `searchsploit linux kernel <version>` — kernel exploits crash boxes; on client engagements treat them as last resort (crash policy in `roe.md`).

## Windows enumeration checklist

- System: `systeminfo` (patch level), `whoami /priv` — **SeImpersonate/SeAssignPrimaryToken → potato family**, SeBackup/SeRestore → read anything.
- Services: weak service permissions (`accesschk -uwcqv "Authenticated Users" *` / PowerUp), unquoted service paths, services running as SYSTEM with writable binaries, DLL hijacking in SYSTEM services.
- Scheduled tasks: tasks running as SYSTEM with writable target or in a writable directory.
- Registry: AlwaysInstallElevated, autologon credentials, saved creds (`cmdkey /list`, runas with saved creds).
- Files: `C:\Users\*\AppData`, unattended installs, GPP cpassword, dev artifacts (`.git`, connection strings, `id_rsa`).
- AD context (domain-joined): current user's groups, Kerberoastable SPNs, AS-REP roastables, credential reuse — the domain-level play goes to the `internal-network` skill; lateral movement needs explicit RoE coverage.

## Escalate & document

One path chosen → exploit → verify (`whoami`) → capture as `<activity>/enum/<host>-privesc.md`: vector, before/after privileges, proof command output. Loot (creds, hashes, keys) goes in `<activity>/evidence/loot.md` — system + account only, secrets stay out of plaintext files.

## Rules

- No credential spraying or reuse beyond what the RoE authorizes; found credentials get used for this host's escalation, lateral movement is `internal-network` territory with its own RoE check.
- If a technique risks crashing the service/host (kernel exploits, memory corruption on production services), flag the risk to the operator before pulling the trigger.
- Clean up: remove dropped enum scripts and staged binaries after the path is proven.
