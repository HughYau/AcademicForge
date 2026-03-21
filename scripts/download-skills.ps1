# Academic Forge - Download Skills Script
# PowerShell version - Downloads skills submodules and syncs skills-only sources

param(
    [switch]$Help,
    [Alias("V")][switch]$Version
)

# Set error action preference
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
        if ($line) { $ver = ($line.Line -replace '.*"(.*)".*', '$1') }
    }
    Write-Host "Academic Forge v$ver"
    exit 0
}

# Load shared library functions
. (Join-Path $PSScriptRoot "lib.ps1")

Write-Host ""
Write-ColorOutput "╔═══════════════════════════════════════════╗" "Blue"
Write-ColorOutput "║                                           ║" "Blue"
Write-ColorOutput "║    📚 Academic Forge - Skills Downloader  ║" "Blue"
Write-ColorOutput "║                                           ║" "Blue"
Write-ColorOutput "╚═══════════════════════════════════════════╝" "Blue"
Write-Host ""

# Check if git is installed
try {
    $null = git --version
    Write-ColorOutput "✓ Git found" "Green"
} catch {
    Write-ColorOutput "❌ Error: git is not installed" "Red"
    Write-Host "Please install git from https://git-scm.com/download/win"
    exit 1
}

# Check if we're in a git repository
if (-not (Test-Path ".git")) {
    Write-ColorOutput "❌ Error: Not in a git repository" "Red"
    Write-Host "Please ensure the script is located inside the AcademicForge repository"
    exit 1
}

Write-Host ""
Write-ColorOutput "📥 Downloading skills..." "Blue"
Write-Host ""

# Initialize and update only skills folder submodules
try {
    # Update .gitmodules configuration
    Write-ColorOutput "→ Initializing submodules..." "Cyan"
    git submodule init

    # Update only skills folder submodules
    Write-ColorOutput "→ Downloading skills submodules..." "Cyan"

    $skillsSubmodules = @(
        "skills/humanizer",
        "skills/AI-research-SKILLs",
        "skills/claude-scientific-skills",
        "skills/paper-polish-workflow-skill"
    )

    foreach ($submodule in $skillsSubmodules) {
        Write-ColorOutput "  ↓ Updating $submodule" "Yellow"
        git submodule update --init --recursive $submodule

        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "  ✓ $submodule downloaded successfully" "Green"
        } else {
            Write-ColorOutput "  ⚠ Warning: Failed to download $submodule" "Red"
        }
    }

    Write-Host ""

    # Sync skills-only snapshots
    Sync-Superpowers
    Write-Host ""
    Sync-PlanningWithFiles

    Write-Host ""

    # Post-sync processing: patch paths, apply blacklist, clean ads
    Invoke-PostSyncAll -BlacklistFile "scripts/skill-blacklist.txt"

    Write-Host ""
    Write-ColorOutput "╔═══════════════════════════════════════════╗" "Green"
    Write-ColorOutput "║                                           ║" "Green"
    Write-ColorOutput "║            ✨ Download Complete!          ║" "Green"
    Write-ColorOutput "║                                           ║" "Green"
    Write-ColorOutput "╚═══════════════════════════════════════════╝" "Green"
    Write-Host ""

    Write-ColorOutput "📂 Skills location: $PWD\skills\" "Blue"
    Write-Host ""
    Write-ColorOutput "Available skills:" "Blue"
    foreach ($submodule in $skillsSubmodules) {
        $skillName = Split-Path -Leaf $submodule
        if (Test-Path $submodule) {
            Write-ColorOutput "  ✓ $skillName" "Green"
        } else {
            Write-ColorOutput "  ✗ $skillName (not found)" "Red"
        }
    }

    if (Test-Path "skills/superpowers") {
        Write-ColorOutput "  ✓ superpowers" "Green"
    } else {
        Write-ColorOutput "  ✗ superpowers (not found)" "Red"
    }

    if (Test-Path "skills/planning-with-files") {
        Write-ColorOutput "  ✓ planning-with-files" "Green"
    } else {
        Write-ColorOutput "  ✗ planning-with-files (not found)" "Red"
    }

    Write-Host ""
    Write-ColorOutput "💡 To update skills later, run this script again" "Blue"

} catch {
    Write-ColorOutput "❌ Error downloading skills: $_" "Red"
    exit 1
}

Write-Host ""
