# Academic Forge - Uninstall Script (PowerShell)
# Removes the Academic Forge installation

param([switch]$Help)

$ErrorActionPreference = "Stop"

# Auto-detect repo root
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")

if ($Help) {
    Write-Host "Usage: .\scripts\uninstall.ps1"
    Write-Host ""
    Write-Host "Removes the Academic Forge installation directory."
    Write-Host "This will delete all skills and configuration in: $RepoRoot"
    exit 0
}

Write-Host "🗑️  Academic Forge - Uninstall" -ForegroundColor Blue
Write-Host ""
Write-Host "This will remove the entire Academic Forge installation at:"
Write-Host "  $RepoRoot" -ForegroundColor Yellow
Write-Host ""

$response = Read-Host "Are you sure you want to uninstall? (y/N)"

if ($response -ne 'y' -and $response -ne 'Y') {
    Write-Host "Uninstall cancelled" -ForegroundColor Red
    exit 0
}

# Move out of the directory before deleting
Set-Location $env:USERPROFILE

Remove-Item -Recurse -Force $RepoRoot

Write-Host "✓ Academic Forge has been uninstalled" -ForegroundColor Green
Write-Host "The directory $RepoRoot has been removed." -ForegroundColor Yellow
