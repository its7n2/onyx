# Onyx

A portable AI penetration-testing agent. Onyx runs consultancy-grade engagements — external network, internal network / Active Directory, web application, API, and mobile — with project-per-customer organization, scope/RoE enforcement, and findings delivery to SysRaptor.

Works with **ZCode** and **Claude Code** (any backend, including z.ai-hosted models via the Claude CLI).

## What it does

- **Kickoff gate** — every session starts by asking for the customer name. New customer → new project folder; existing customer → a new activity is added to their folder. No testing before scope + RoE are written and confirmed.
- **Phase skills** — one skill per pentest phase: recon → service enumeration → network/web/API/mobile exploitation → privesc → reporting.
- **Project folders** — `projects/<customer>/<date>_<activity-type>/` holding scope.md, roe.md, recon, enum, findings (F-01, F-02...), evidence, notes, and the report. Customer data is gitignored and never leaves the machine.
- **SysRaptor delivery** — findings written during testing push straight into SysRaptor via its API (confirm-first).

## Layout

```
agents/AGENTS.md    the persona (installed as AGENTS.md / CLAUDE.md)
skills/             13 phase skills (one SKILL.md each)
templates/          profile, scope, roe, finding templates
projects/           engagement data — gitignored, lives with the repo
install.ps1|.sh     installers
```

## Install

```powershell
# Windows (ZCode + Claude Code)
powershell -ExecutionPolicy Bypass -File install.ps1
```

```bash
# Linux / Kali / macOS (ZCode + Claude Code)
chmod +x install.sh && ./install.sh
```

Restart your CLI session. Onyx opens with: *"Onyx online. Who are we working for — new client or existing project?"*

## Skills

| Skill | Phase |
|---|---|
| `engagement-setup` | kickoff router — customer → project → activity → scope + RoE |
| `pentest-scope` | scope/RoE enforcement gate |
| `recon` | external attack-surface mapping |
| `service-enumeration` | port/service/content enumeration (external + internal) |
| `internal-network` | AD & internal: spraying, Kerberoast, BloodHound, lateral movement |
| `privesc` | Linux/Windows privilege escalation |
| `webapp-testing` | OWASP web workflow |
| `api-testing` | REST + GraphQL |
| `mobile-testing` | Android-first static/dynamic, iOS where tooling allows |
| `exploit-dev` | binary exploitation & PoC engineering |
| `nuclei-hunting` | safe sweeps + custom template authoring |
| `report-writing` | findings, severity, full report |
| `sysraptor` | push findings to SysRaptor via API |

## SysRaptor configuration

Set the API key as an environment variable:

```bash
export ONYX_SYSRAPTOR_API_KEY="..."
```

or create `sysraptor.local.json` at the repo root (gitignored). The API endpoint map in `skills/sysraptor/SKILL.md` is filled in once, from your API documentation — until then the skill preps findings and stops before pushing.

## Claude Code + z.ai

The installer copies `agents/AGENTS.md` to `~/.claude/CLAUDE.md` and the skills to `~/.claude/skills/` — Claude Code picks them up natively. To run Claude CLI against z.ai models, configure your environment per z.ai's docs, e.g.:

```bash
export ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic"
export ANTHROPIC_AUTH_TOKEN="<your z.ai key>"
```

## Transferring to a new machine

```bash
git clone <your-repo-url> onyx && cd onyx
./install.sh            # or: powershell -File install.ps1
```

Projects live inside the cloned repo folder — copy them over separately (never via git; they're ignored).

## Rules Onyx enforces

- Scope card is law — no testing outside `scope.md`, no destructive actions, production stays up.
- Nothing gets reported that wasn't reproduced.
- External writes (SysRaptor pushes, client delivery) are confirm-first, every time.
