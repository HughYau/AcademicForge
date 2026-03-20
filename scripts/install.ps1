# Academic Forge Installation Script for Windows
# PowerShell version

param(
    [string]$InstallDir = "",
    [string]$Tool = "",
    [switch]$Help,
    [Alias("V")][switch]$Version
)

# Set error action preference
$ErrorActionPreference = "Stop"

if ($Help) {
    Write-Host "Usage: .\scripts\install.ps1 [--tool claude|opencode] [-InstallDir <path>]"
    Write-Host ""
    Write-Host "Installs Academic Forge into your project."
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Tool <name>       Target tool: 'claude' or 'opencode'"
    Write-Host "  -InstallDir <path> Custom installation directory"
    Write-Host "  -Help              Show this help message"
    Write-Host "  -Version, -V       Show forge version"
    Write-Host ""
    Write-Host "If no -Tool or -InstallDir is given, auto-detects .claude/ or .opencode/."
    exit 0
}

if ($Version) {
    Write-Host "Academic Forge installer"
    exit 0
}

# Determine install directory based on tool type
if (-not $InstallDir) {
    if ($Tool) {
        switch ($Tool.ToLower()) {
            "claude"   { $InstallDir = ".claude\skills\academic-forge" }
            "opencode" { $InstallDir = ".opencode\skills\academic-forge" }
            default {
                Write-Host "Unknown tool: $Tool" -ForegroundColor Red
                Write-Host "Supported: claude, opencode"
                Write-Host "Or provide a custom path with -InstallDir."
                exit 1
            }
        }
    } else {
        # Auto-detect: prefer .claude if it exists, otherwise .opencode
        if (Test-Path ".claude") {
            $InstallDir = ".claude\skills\academic-forge"
        } else {
            $InstallDir = ".opencode\skills\academic-forge"
        }
    }
}

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
    git clone --recursive https://github.com/HughYau/AcademicForge $InstallDir
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

# Load shared library functions (now that we're in the cloned repo)
. (Join-Path "scripts" "lib.ps1")

# Sync skills-only snapshots
try {
    Sync-Superpowers
} catch {
    Write-ColorOutput "❌ Failed to sync superpowers skills" "Red"
    Pop-Location
    exit 1
}

try {
    Sync-PlanningWithFiles
} catch {
    Write-ColorOutput "❌ Failed to sync planning-with-files skill" "Red"
    Pop-Location
    exit 1
}

# Post-sync processing: patch paths, apply blacklist, clean ads
try {
    Invoke-PostSyncAll -BlacklistFile "scripts/skill-blacklist.txt"
} catch {
    Write-ColorOutput "❌ Failed post-sync processing" "Red"
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
Write-Host "  ✓ skills/superpowers"
Write-Host "  ✓ skills/planning-with-files"

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
