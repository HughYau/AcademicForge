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

Write-Host ""
Write-ColorOutput "📊 Update Summary:" "Blue"
Write-Host ""

# Show status of each submodule
git submodule foreach 'echo "📚 $name:"; git log --oneline -3 --decorate; echo ""'

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
