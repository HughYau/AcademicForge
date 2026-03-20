# Academic Forge - List Installed Skills (PowerShell)
# Displays all installed skills with their descriptions

param([switch]$Help)

$ErrorActionPreference = "Continue"

# Auto-detect repo root
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $RepoRoot

if ($Help) {
    Write-Host "Usage: .\scripts\list-skills.ps1"
    Write-Host ""
    Write-Host "Lists all installed Academic Forge skills with their descriptions."
    exit 0
}

Write-Host "📚 Academic Forge - Installed Skills" -ForegroundColor Blue
Write-Host ""

$total = 0
$packs = 0

foreach ($skillDir in Get-ChildItem "skills" -Directory -ErrorAction SilentlyContinue) {
    $skillFiles = Get-ChildItem $skillDir.FullName -Filter "SKILL.md" -Recurse -ErrorAction SilentlyContinue
    if (-not $skillFiles -or $skillFiles.Count -eq 0) { continue }

    $packs++
    $count = $skillFiles.Count
    Write-Host "━━ $($skillDir.Name) ($count skills) ━━" -ForegroundColor Cyan

    # Show top-level SKILL.md description
    $topSkill = Join-Path $skillDir.FullName "SKILL.md"
    if (Test-Path $topSkill) {
        $content = Get-Content $topSkill -Raw -ErrorAction SilentlyContinue
        if ($content -match '(?m)^description:\s*(.+)$') {
            $desc = $Matches[1].Trim().Trim('"')
            Write-Host "  $desc"
        }
    }

    # List sub-skills if more than 1
    if ($count -gt 1) {
        foreach ($sf in $skillFiles | Sort-Object FullName) {
            $relDir = Split-Path -Parent $sf.FullName
            $skillName = Split-Path -Leaf $relDir
            if ($skillName -eq $skillDir.Name) { continue }

            $content = Get-Content $sf.FullName -Raw -ErrorAction SilentlyContinue
            $desc = ""
            if ($content -match '(?m)^description:\s*(.+)$') {
                $desc = $Matches[1].Trim().Trim('"')
                if ($desc.Length -gt 80) { $desc = $desc.Substring(0, 77) + "..." }
            }

            if ($desc) {
                Write-Host "  $skillName" -ForegroundColor Green -NoNewline
                Write-Host ": $desc"
            } else {
                Write-Host "  $skillName" -ForegroundColor Green
            }
        }
    }

    $total += $count
    Write-Host ""
}

Write-Host "Total: $total skills across $packs packs" -ForegroundColor Blue
