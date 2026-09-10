#!/usr/bin/env bash
# Onyx installer (Linux/Kali/macOS) — copies the persona and skills into user config dirs
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

install_to() {
    local persona="$1" skills="$2"
    mkdir -p "$(dirname "$persona")" "$skills"
    cp "$root/agents/AGENTS.md" "$persona"
    echo "  persona -> $persona"
    for d in "$root"/skills/*/; do
        cp -r "${d%/}" "$skills/"
    done
    echo "  skills  -> $skills"
}

install_to "$HOME/.zcode/AGENTS.md" "$HOME/.agents/skills"   # ZCode
install_to "$HOME/.claude/CLAUDE.md" "$HOME/.claude/skills"  # Claude Code

# Projects folder stays with the repo (gitignored)
mkdir -p "$root/projects"
touch "$root/projects/.gitkeep"

echo ""
echo "Onyx installed. Restart your CLI session to load the persona."
echo "Optional: export ONYX_SYSRAPTOR_API_KEY or create sysraptor.local.json at the repo root."
