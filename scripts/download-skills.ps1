# Academic Forge - Download Skills Script
# PowerShell version - Downloads skills submodules and syncs skills-only sources

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
    Write-ColorOutput "→ Syncing skills/superpowers (skills-only)..." "Cyan"

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

    Write-ColorOutput "  ✓ skills/superpowers synced successfully" "Green"

    Write-Host ""
    Write-ColorOutput "→ Applying skill blacklist..." "Cyan"
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
    Write-ColorOutput "  ✓ Skill blacklist applied" "Green"
    
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
    
    Write-Host ""
    Write-ColorOutput "💡 To update skills later, run this script again" "Blue"
    
} catch {
    Write-ColorOutput "❌ Error downloading skills: $_" "Red"
    exit 1
}

Write-Host ""
