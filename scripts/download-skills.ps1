# Academic Forge - Download Skills Script
# PowerShell version - Downloads skills submodules and syncs skills-only sources

param(
    [switch]$Help,
    [Alias("V")][switch]$Version
)

$ErrorActionPreference = "Stop"

# Auto-detect repo root from script location
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $RepoRoot

if ($Help) {
    Write-Host "Usage: .\scripts\download-skills.ps1"
    Write-Host ""
    Write-Host "Downloads and syncs all Academic Forge skills (submodules + skills-only snapshots)."
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Help              Show this help message"
    Write-Host "  -Version, -V       Show forge version"
    exit 0
}

if ($Version) {
    $ver = "unknown"
    if (Test-Path "forge.yaml") {
        $line = Select-String -Path "forge.yaml" -Pattern 'version:' | Select-Object -First 1
        if ($line) {
            $ver = ($line.Line -replace '.*"(.*)".*', '$1')
        }
    }
    Write-Host "Academic Forge v$ver"
    exit 0
}

# Load shared library functions
. (Join-Path $PSScriptRoot "lib.ps1")

Write-Host ""
Write-ColorOutput "Academic Forge - Skills Downloader" "Blue"
Write-Host ""

try {
    $null = git --version
    Write-ColorOutput "Git found" "Green"
} catch {
    Write-ColorOutput "ERROR: git is not installed" "Red"
    Write-Host "Please install git from https://git-scm.com/download/win"
    exit 1
}

if (-not (Test-Path ".git")) {
    Write-ColorOutput "ERROR: Not in a git repository" "Red"
    Write-Host "Please ensure the script is located inside the AcademicForge repository"
    exit 1
}

Write-Host ""
Write-ColorOutput "Downloading skills..." "Blue"
Write-Host ""

$skillsSubmodules = @(
    "skills/humanizer",
    "skills/humanizer-zh",
    "skills/AI-research-SKILLs",
    "skills/scientific-agent-skills",
    "skills/paper-polish-workflow-skill"
)

Write-ColorOutput "Initializing submodules..." "Cyan"
git submodule init
git submodule sync --recursive
Remove-LegacyScientificSkillsPath

Write-ColorOutput "Downloading skills submodules..." "Cyan"
foreach ($submodule in $skillsSubmodules) {
    Write-ColorOutput "  Updating $submodule" "Yellow"
    git submodule update --init --recursive $submodule

    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "  OK: $submodule downloaded successfully" "Green"
    } else {
        Write-ColorOutput "  WARNING: Failed to download $submodule" "Red"
    }
}

Write-Host ""
Sync-Superpowers

Write-Host ""
Invoke-PostSyncAll -BlacklistFile "scripts/skill-blacklist.txt"

Write-Host ""
Write-ColorOutput "Download complete" "Green"
Write-Host ""

$skillsPath = Join-Path $PWD "skills"
Write-ColorOutput "Skills location: $skillsPath" "Blue"
Write-Host ""
Write-ColorOutput "Available skills:" "Blue"

foreach ($submodule in $skillsSubmodules) {
    $skillName = Split-Path -Leaf $submodule
    if (Test-Path $submodule) {
        Write-ColorOutput "  OK: $skillName" "Green"
    } else {
        Write-ColorOutput "  MISSING: $skillName" "Red"
    }
}

if (Test-Path "skills/superpowers") {
    Write-ColorOutput "  OK: superpowers" "Green"
} else {
    Write-ColorOutput "  MISSING: superpowers" "Red"
}

Write-Host ""
Write-ColorOutput "To update skills later, run this script again" "Blue"

Write-Host ""
