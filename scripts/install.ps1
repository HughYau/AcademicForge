# Academic Forge Installation Script for Windows
# PowerShell version

param(
    [string]$InstallDir = ".opencode\skills\academic-forge"
)

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
Write-ColorOutput "║        🎓 Academic Forge Installer        ║" "Blue"
Write-ColorOutput "║                                           ║" "Blue"
Write-ColorOutput "╚═══════════════════════════════════════════╝" "Blue"
Write-Host ""

# Check if git is installed
try {
    $null = git --version
} catch {
    Write-ColorOutput "❌ Error: git is not installed" "Red"
    Write-Host "Please install git from https://git-scm.com/download/win"
    exit 1
}

Write-ColorOutput "📍 Installation directory: $InstallDir" "Blue"
Write-Host ""

# Check if directory already exists
if (Test-Path $InstallDir) {
    Write-ColorOutput "⚠️  Directory already exists: $InstallDir" "Yellow"
    $response = Read-Host "Do you want to remove it and reinstall? (y/N)"
    
    if ($response -eq 'y' -or $response -eq 'Y') {
        Remove-Item -Recurse -Force $InstallDir
        Write-ColorOutput "✓ Removed existing directory" "Green"
    } else {
        Write-ColorOutput "Installation cancelled" "Red"
        exit 0
    }
}

# Create parent directory if it doesn't exist
$parentDir = Split-Path -Parent $InstallDir
if (-not (Test-Path $parentDir)) {
    New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
}

Write-ColorOutput "📦 Cloning Academic Forge..." "Blue"

try {
    git clone --recursive https://github.com/your-username/academic-forge $InstallDir
    Write-ColorOutput "✓ Successfully cloned Academic Forge" "Green"
} catch {
    Write-ColorOutput "❌ Failed to clone repository" "Red"
    Write-Host $_.Exception.Message
    exit 1
}

# Initialize submodules
Write-ColorOutput "🔄 Ensuring all skills are initialized..." "Blue"
Push-Location $InstallDir

try {
    git submodule update --init --recursive
    Write-ColorOutput "✓ All skills initialized" "Green"
} catch {
    Write-ColorOutput "❌ Failed to initialize submodules" "Red"
    Pop-Location
    exit 1
}

Write-Host ""
Write-ColorOutput "╔═══════════════════════════════════════════╗" "Green"
Write-ColorOutput "║                                           ║" "Green"
Write-ColorOutput "║     ✨ Installation Complete! ✨          ║" "Green"
Write-ColorOutput "║                                           ║" "Green"
Write-ColorOutput "╚═══════════════════════════════════════════╝" "Green"
Write-Host ""

Write-ColorOutput "📚 Included Skills:" "Blue"
git submodule foreach --quiet 'echo "  ✓ $name"'

Pop-Location

Write-Host ""
Write-ColorOutput "📖 Next Steps:" "Blue"
Write-Host "  1. Restart Claude Code to load the new skills"
Write-Host "  2. Check forge.yaml for configuration options"
Write-Host "  3. Run '$InstallDir\scripts\update.ps1' to update skills later"
Write-Host ""
Write-ColorOutput "📄 Documentation:" "Blue"
Write-Host "  - README.md: Overview and usage guide"
Write-Host "  - ATTRIBUTIONS.md: Skill credits and licenses"
Write-Host "  - forge.yaml: Configuration options"
Write-Host ""
Write-ColorOutput "Happy writing! 🎓📝" "Green"
