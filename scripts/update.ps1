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

Write-ColorOutput "🔄 Syncing planning-with-files (skills-only)..." "Blue"

try {
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

    Write-ColorOutput "✓ planning-with-files skill synced" "Green"
} catch {
    Write-ColorOutput "❌ Failed to sync planning-with-files skill" "Red"
    exit 1
}

Write-ColorOutput "🧹 Applying skill blacklist..." "Blue"

try {
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

    Write-ColorOutput "✓ Skill blacklist applied" "Green"
} catch {
    Write-ColorOutput "❌ Failed to apply skill blacklist" "Red"
    exit 1
}

Write-ColorOutput "🧹 Cleaning ad insertions from claude-scientific-skills..." "Blue"
try {
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
        Write-ColorOutput "✓ Cleaned ad sections from $cleanedCount SKILL.md file(s)" "Green"
    }
} catch {
    Write-ColorOutput "❌ Failed to clean ad insertions" "Red"
    exit 1
}

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
