# Onyx installer (Windows) — copies the persona and skills into user config dirs
# Usage: powershell -ExecutionPolicy Bypass -File install.ps1
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path

$targets = @(
    @{ Persona = "$HOME\.zcode\AGENTS.md";  Skills = "$HOME\.agents\skills" },   # ZCode
    @{ Persona = "$HOME\.claude\CLAUDE.md"; Skills = "$HOME\.claude\skills" }    # Claude Code
)

foreach ($t in $targets) {
    $personaDir = Split-Path -Parent $t.Persona
    if (-not (Test-Path $personaDir)) { New-Item -ItemType Directory -Path $personaDir -Force | Out-Null }
    Copy-Item -Path "$root\agents\AGENTS.md" -Destination $t.Persona -Force
    Write-Host "  persona -> $($t.Persona)"

    if (-not (Test-Path $t.Skills)) { New-Item -ItemType Directory -Path $t.Skills -Force | Out-Null }
    Get-ChildItem -Path "$root\skills" -Directory | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination $t.Skills -Recurse -Force
    }
    Write-Host "  skills  -> $($t.Skills)"
}

# Projects folder stays with the repo (gitignored) — create the keepfile
if (-not (Test-Path "$root\projects")) { New-Item -ItemType Directory -Path "$root\projects" | Out-Null }
New-Item -ItemType File -Path "$root\projects\.gitkeep" -Force | Out-Null

Write-Host ""
Write-Host "Onyx installed. Restart your CLI session to load the persona."
Write-Host "Optional: SysReptor config at repo root (sysreptor.local.json) or ONYX_SYSREPTOR_API_KEY env var."
