# Academic Forge Update Script for Windows
# PowerShell version

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
    Write-Host "Usage: .\scripts\update.ps1"
    Write-Host ""
    Write-Host "Updates Academic Forge and all included skills to their latest versions."
    Write-Host "This includes git submodules, skills-only snapshots, and post-sync processing."
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
Write-ColorOutput "║       🔄 Academic Forge Updater           ║" "Blue"
Write-ColorOutput "║                                           ║" "Blue"
Write-ColorOutput "╚═══════════════════════════════════════════╝" "Blue"
Write-Host ""

# Check if we're in the forge directory
if (-not (Test-Path "forge.yaml")) {
    Write-ColorOutput "❌ Error: Not in Academic Forge directory" "Red"
    Write-Host "Please ensure the script is located inside the forge repository"
    exit 1
}

# Check for uncommitted changes
$gitStatus = git status --porcelain
if ($gitStatus) {
    Write-ColorOutput "⚠️  Warning: You have uncommitted changes" "Yellow"
    Write-Host "It's recommended to commit or stash changes before updating."
    $response = Read-Host "Continue anyway? (y/N)"

    if ($response -ne 'y' -and $response -ne 'Y') {
        Write-ColorOutput "Update cancelled" "Red"
        exit 0
    }
}

# Update the forge repository itself
Write-ColorOutput "📦 Updating forge repository..." "Blue"

try {
    git pull origin main 2>$null
    Write-ColorOutput "✓ Forge repository updated" "Green"
} catch {
    try {
        git pull origin master 2>$null
        Write-ColorOutput "✓ Forge repository updated" "Green"
    } catch {
        Write-ColorOutput "⚠️  Could not update forge repository (might be on a detached HEAD)" "Yellow"
    }
}

Write-Host ""
Write-ColorOutput "🔄 Updating all skills..." "Blue"
Write-Host ""

# Update all submodules
try {
    git submodule update --remote --merge
    Write-ColorOutput "✓ All submodule skills updated" "Green"
} catch {
    Write-ColorOutput "❌ Some skills failed to update" "Red"
    Write-Host "You may need to resolve conflicts manually"
    exit 1
}

# Sync skills-only snapshots
Sync-Superpowers
Sync-PlanningWithFiles

# Post-sync processing: patch paths, apply blacklist, clean ads
Invoke-PostSyncAll -BlacklistFile "scripts/skill-blacklist.txt"

Write-Host ""
Write-ColorOutput "📊 Update Summary:" "Blue"
Write-Host ""

# Show status of each submodule
git submodule foreach 'echo "📚 $name:"; git log --oneline -3 --decorate; echo ""'
Write-Host "📚 skills/superpowers: synced from obra/superpowers (skills/)"
Write-Host "📚 skills/planning-with-files: synced from OthmanAdi/planning-with-files (.opencode/skills/planning-with-files)"
Write-Host ""

Write-Host ""
Write-ColorOutput "╔═══════════════════════════════════════════╗" "Green"
Write-ColorOutput "║                                           ║" "Green"
Write-ColorOutput "║        ✨ Update Complete! ✨             ║" "Green"
Write-ColorOutput "║                                           ║" "Green"
Write-ColorOutput "╚═══════════════════════════════════════════╝" "Green"
Write-Host ""

Write-ColorOutput "📖 Next Steps:" "Blue"
Write-Host "  1. Review changes: git status"
Write-Host "  2. Test the updated skills with your projects"
Write-Host "  3. Commit if everything works: git add . && git commit -m 'Update skills'"
Write-Host ""

# Check if there are any changes to commit
$gitStatus = git status --porcelain
if ($gitStatus) {
    Write-ColorOutput "⚠️  You have uncommitted changes after the update" "Yellow"
    Write-Host "Run 'git status' to see what changed"
    Write-Host ""
    $response = Read-Host "Would you like to commit these changes? (y/N)"

    if ($response -eq 'y' -or $response -eq 'Y') {
        git add .
        git commit -m "chore: update skills to latest versions"
        Write-ColorOutput "✓ Changes committed" "Green"
    }
}

Write-ColorOutput "Happy writing! 🎓📝" "Green"
