# Academic Forge - Installation Verification Script (PowerShell)
# Checks that all skills are properly installed and configured

param(
    [switch]$Help,
    [switch]$Version
)

$ErrorActionPreference = "Continue"

# Auto-detect repo root
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $RepoRoot

if ($Help) {
    Write-Host "Usage: .\scripts\verify.ps1"
    Write-Host ""
    Write-Host "Verifies that Academic Forge is correctly installed by checking:"
    Write-Host "  - forge.yaml exists"
    Write-Host "  - All skill directories are present and non-empty"
    Write-Host "  - Git submodules are initialized"
    exit 0
}

if ($Version) {
    $ver = (Select-String -Path "forge.yaml" -Pattern 'version:' | Select-Object -First 1).Line -replace '.*"(.*)".*', '$1'
    Write-Host "Academic Forge v$ver"
    exit 0
}

Write-Host "🔍 Academic Forge - Installation Verification" -ForegroundColor Blue
Write-Host ""

$passed = 0
$failed = 0
$warnings = 0

function Check-Pass($msg) { Write-Host "  ✓ $msg" -ForegroundColor Green; $script:passed++ }
function Check-Fail($msg) { Write-Host "  ✗ $msg" -ForegroundColor Red; $script:failed++ }
function Check-Warn($msg) { Write-Host "  ⚠ $msg" -ForegroundColor Yellow; $script:warnings++ }

# 1. Check forge.yaml
Write-Host "Checking forge configuration..." -ForegroundColor Blue
if (Test-Path "forge.yaml") { Check-Pass "forge.yaml found" } else { Check-Fail "forge.yaml not found" }

# 2. Check skill directories
Write-Host "Checking skill directories..." -ForegroundColor Blue

$skills = @(
    "skills/claude-scientific-skills",
    "skills/AI-research-SKILLs",
    "skills/humanizer",
    "skills/superpowers",
    "skills/planning-with-files",
    "skills/paper-polish-workflow-skill",
    "skills/scientific-visualization"
)

foreach ($skillDir in $skills) {
    $skillName = Split-Path -Leaf $skillDir
    if ((Test-Path $skillDir) -and (Get-ChildItem $skillDir -ErrorAction SilentlyContinue | Select-Object -First 1)) {
        Check-Pass $skillName
    } elseif (Test-Path $skillDir) {
        Check-Warn "$skillName (directory exists but is empty - run download-skills.ps1)"
    } else {
        Check-Fail "$skillName (not found)"
    }
}

# 3. Check submodule status
Write-Host "Checking git submodules..." -ForegroundColor Blue
if (Test-Path ".git") {
    $subStatus = git submodule status 2>$null
    if ($subStatus) {
        foreach ($line in $subStatus) {
            $parts = $line.Trim() -split '\s+'
            $name = $parts[1]
            if ($line.TrimStart().StartsWith('-')) {
                Check-Warn "$name (not initialized - run: git submodule update --init)"
            } elseif ($line.TrimStart().StartsWith('+')) {
                Check-Warn "$name (has local changes)"
            } else {
                Check-Pass "$name (initialized)"
            }
        }
    }
}

# 4. Check shared library
Write-Host "Checking scripts..." -ForegroundColor Blue
if (Test-Path "scripts/lib.ps1") { Check-Pass "scripts/lib.ps1 found" } else { Check-Fail "scripts/lib.ps1 not found" }

# Summary
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host "  Passed: $passed  Failed: $failed  Warnings: $warnings"
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue

if ($failed -eq 0) {
    Write-Host "✨ Academic Forge is correctly installed!" -ForegroundColor Green
} else {
    Write-Host "Some checks failed. Run '.\scripts\download-skills.ps1' to fix." -ForegroundColor Red
    exit 1
}
