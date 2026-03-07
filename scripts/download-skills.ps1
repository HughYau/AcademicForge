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
    Write-ColorOutput "→ Syncing skills/planning-with-files (skills-only)..." "Cyan"

    $tempDir = ".tmp-planning-with-files-sync"
    if (Test-Path $tempDir) {
        Remove-Item -Recurse -Force $tempDir
    }

    git clone --depth 1 --filter=blob:none --sparse https://github.com/OthmanAdi/planning-with-files.git $tempDir
    git -C $tempDir sparse-checkout set .opencode/skills/planning-with-files

    if (Test-Path "skills/planning-with-files") {
        Remove-Item -Recurse -Force "skills/planning-with-files"
    }
    New-Item -ItemType Directory -Path "skills/planning-with-files" -Force | Out-Null
    Copy-Item -Path "$tempDir/.opencode/skills/planning-with-files/*" -Destination "skills/planning-with-files" -Recurse -Force
    Remove-Item -Recurse -Force $tempDir

    Write-ColorOutput "  ✓ skills/planning-with-files synced successfully" "Green"

    Write-Host ""
    Write-ColorOutput "→ Applying skill blacklist..." "Cyan"
    $repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
    $blacklistFile = Join-Path $repoRoot "scripts/skill-blacklist.txt"
    if (Test-Path $blacklistFile) {
        foreach ($rawSkillPath in Get-Content $blacklistFile) {
            $skillPath = $rawSkillPath.Trim()
            if (-not $skillPath -or $skillPath.StartsWith("#")) {
                continue
            }

            $targetPath = if ([System.IO.Path]::IsPathRooted($skillPath)) {
                $skillPath
            } else {
                Join-Path $repoRoot $skillPath
            }

            if (Test-Path -LiteralPath $targetPath) {
                Remove-Item -Recurse -Force -LiteralPath $targetPath
                Write-ColorOutput "  - Removed blacklisted skill: $skillPath" "Yellow"
            } else {
                Write-ColorOutput "  - Blacklist entry not found (skipped): $skillPath" "DarkYellow"
            }
        }
    }
    Write-ColorOutput "  ✓ Skill blacklist applied" "Green"

    Write-Host ""
    Write-ColorOutput "→ Cleaning ad insertions from claude-scientific-skills..." "Cyan"
    $adSkillDir = "skills/claude-scientific-skills"
    if (Test-Path $adSkillDir) {
        $skillFiles = Get-ChildItem -Path $adSkillDir -Filter "SKILL.md" -Recurse
        $cleanedCount = 0
        foreach ($file in $skillFiles) {
            $content = Get-Content $file.FullName -Raw -Encoding UTF8
            if ($content -match "## Suggest Using K-Dense Web") {
                $newContent = $content -replace "(?s)`r?`n+## Suggest Using K-Dense Web.*", ""
                Set-Content -Path $file.FullName -Value $newContent -NoNewline -Encoding UTF8
                $cleanedCount++
            }
        }
        Write-ColorOutput "  ✓ Cleaned ad sections from $cleanedCount SKILL.md file(s)" "Green"
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
