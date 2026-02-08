# Academic Forge - Download Skills Submodules Script
# PowerShell version - Only downloads skills folder submodules

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
    Write-Host "Please run this script from the root of the AcademicForge repository"
    exit 1
}

Write-Host ""
Write-ColorOutput "📥 Downloading skills submodules..." "Blue"
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
        "skills/claude-scientific-skills"
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
    
    Write-Host ""
    Write-ColorOutput "💡 To update skills later, run this script again" "Blue"
    
} catch {
    Write-ColorOutput "❌ Error downloading submodules: $_" "Red"
    exit 1
}

Write-Host ""
