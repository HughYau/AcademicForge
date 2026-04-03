# Academic Forge - Shared Library Functions (PowerShell)
# Provides common functions for sync, patching, blacklist, and ad cleaning.
# Dot-source this file from other scripts: . (Join-Path $PSScriptRoot "lib.ps1")

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

# Sync superpowers skills-only snapshot from upstream
function Sync-Superpowers {
    Write-ColorOutput "🔄 Syncing superpowers (skills-only)..." "Blue"

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
}

# Apply skill blacklist - removes unwanted skills listed in skill-blacklist.txt
function Apply-SkillBlacklist {
    param(
        [string]$BlacklistFile = "scripts/skill-blacklist.txt"
    )

    Write-ColorOutput "🧹 Applying skill blacklist..." "Blue"

    if (Test-Path $BlacklistFile) {
        foreach ($rawSkillPath in Get-Content $BlacklistFile) {
            $skillPath = $rawSkillPath.Trim()
            if (-not $skillPath -or $skillPath.StartsWith("#")) {
                continue
            }

            if (Test-Path -LiteralPath $skillPath) {
                Remove-Item -Recurse -Force -LiteralPath $skillPath
                Write-ColorOutput "  - Removed blacklisted skill: $skillPath" "Yellow"
            } else {
                Write-ColorOutput "  - Blacklist entry not found (skipped): $skillPath" "DarkYellow"
            }
        }
    }

    Write-ColorOutput "✓ Skill blacklist applied" "Green"
}

# Clean K-Dense ad insertions from claude-scientific-skills SKILL.md files
function Clean-AdInsertions {
    Write-ColorOutput "🧹 Cleaning ad insertions from claude-scientific-skills..." "Blue"

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
}

# Apply forge.yaml enabled flags - removes disabled skills' directories
function Apply-ForgeConfig {
    param(
        [string]$ConfigFile = "forge.yaml"
    )

    if (-not (Test-Path $ConfigFile)) {
        return
    }

    Write-ColorOutput "🔧 Applying forge.yaml configuration..." "Blue"

    $skillPaths = @{
        "claude-scientific-skills" = "skills/claude-scientific-skills"
        "AI-research-SKILLs"      = "skills/AI-research-SKILLs"
        "humanizer"               = "skills/humanizer"
        "humanizer-zh"            = "skills/humanizer-zh"
        "superpowers"             = "skills/superpowers"
        "paper-polish-workflow-skill" = "skills/paper-polish-workflow-skill"
        "scientific-visualization" = "skills/scientific-visualization"
    }

    $lines = Get-Content $ConfigFile
    $inEnabled = $false

    foreach ($line in $lines) {
        if ($line -match '^\s*enabled:') {
            $inEnabled = $true
            continue
        }
        if ($inEnabled -and $line -match '^[a-z]') {
            break
        }
        if ($inEnabled -and $line -match '^\s+([\w-]+):\s*false') {
            $skillName = $Matches[1]
            $skillDir = $skillPaths[$skillName]
            if ($skillDir -and (Test-Path $skillDir)) {
                Remove-Item -Recurse -Force $skillDir
                Write-ColorOutput "  - Disabled skill removed: $skillName ($skillDir)" "Yellow"
            }
        }
    }

    Write-ColorOutput "✓ forge.yaml configuration applied" "Green"
}

# Run all post-sync processing steps
function Invoke-PostSyncAll {
    param(
        [string]$BlacklistFile = "scripts/skill-blacklist.txt"
    )

    Apply-SkillBlacklist -BlacklistFile $BlacklistFile
    Clean-AdInsertions
    Apply-ForgeConfig
}
