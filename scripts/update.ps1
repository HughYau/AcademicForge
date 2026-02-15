# Academic Forge Update Script for Windows
# PowerShell version

# Set error action preference
$ErrorActionPreference = "Stop"

# Colors
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

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
    Write-Host "Please run this script from the forge root directory"
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
    git pull origin main
    Write-ColorOutput "✓ Forge repository updated" "Green"
} catch {
    try {
        git pull origin master
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
    Write-ColorOutput "✓ All skills updated" "Green"
} catch {
    Write-ColorOutput "❌ Some skills failed to update" "Red"
    Write-Host "You may need to resolve conflicts manually"
    exit 1
}

Write-ColorOutput "🔄 Syncing superpowers (skills-only)..." "Blue"

try {
    $tempDir = ".tmp-superpowers-sync"
    if (Test-Path $tempDir) {
        Remove-Item -Recurse -Force $tempDir
    }

    git clone --depth 1 --filter=blob:none --sparse https://github.com/obra/superpowers.git $tempDir
    git -C $tempDir sparse-checkout set skills

    if (Test-Path "skills/superpowers") {
        Remove-Item -Recurse -Force "skills/superpowers"
    }
    New-Item -ItemType Directory -Path "skills/superpowers" -Force | Out-Null
    Copy-Item -Path "$tempDir/skills/*" -Destination "skills/superpowers" -Recurse -Force
    Remove-Item -Recurse -Force $tempDir

    Write-ColorOutput "✓ superpowers skills synced" "Green"
} catch {
    Write-ColorOutput "❌ Failed to sync superpowers skills" "Red"
    exit 1
}

Write-ColorOutput "🧹 Applying skill blacklist..." "Blue"

try {
    $blacklistFile = "scripts/skill-blacklist.txt"
    if (Test-Path $blacklistFile) {
        $blacklistPaths = Get-Content $blacklistFile | Where-Object {
            $_ -and $_.Trim() -ne "" -and -not $_.Trim().StartsWith("#")
        }

        foreach ($skillPath in $blacklistPaths) {
            if (Test-Path $skillPath) {
                Remove-Item -Recurse -Force $skillPath
                Write-ColorOutput "  - Removed blacklisted skill: $skillPath" "Yellow"
            }
        }
    }

    Write-ColorOutput "✓ Skill blacklist applied" "Green"
} catch {
    Write-ColorOutput "❌ Failed to apply skill blacklist" "Red"
    exit 1
}

Write-Host ""
Write-ColorOutput "📊 Update Summary:" "Blue"
Write-Host ""

# Show status of each submodule
git submodule foreach 'echo "📚 $name:"; git log --oneline -3 --decorate; echo ""'
Write-Host "📚 skills/superpowers: synced from obra/superpowers (skills/)"
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
