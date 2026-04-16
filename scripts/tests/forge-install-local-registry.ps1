Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$TempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('forge-install-test-' + [System.Guid]::NewGuid().ToString('N'))
$RegistryPath = Join-Path $TempRoot 'registry.json'
$OutputPath = Join-Path $TempRoot 'output'
$LocalRef = (& git -C $RepoRoot rev-parse HEAD).Trim()

New-Item -ItemType Directory -Path $TempRoot | Out-Null

try {
    @{
        skills = @(
            @{
                id = 'scientific-visualization'
                name = 'Scientific Visualization'
                summary = @{
                    en = 'local test'
                    zh = 'local test'
                }
                author = 'AcademicForge'
                repository = 'https://github.com/HughYau/AcademicForge'
                license = 'MIT'
                skill_count = 1
                stars = 0
                tags = @('visualization')
                install = @{
                    method = 'sparse-checkout'
                    url = $RepoRoot
                    ref = $LocalRef
                    sparse_path = 'skills/scientific-visualization'
                }
                post_install = @()
            }
        )
    } | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $RegistryPath -Encoding UTF8

    & (Join-Path $RepoRoot 'scripts\forge-install.ps1') `
        -Tool opencode `
        -Skills 'scientific-visualization' `
        -Registry $RegistryPath `
        -Path $OutputPath

    if (-not (Test-Path -LiteralPath (Join-Path $OutputPath 'scientific-visualization\SKILL.md'))) {
        throw 'scientific-visualization did not install into the output path'
    }
}
finally {
    if (Test-Path -LiteralPath $TempRoot) {
        Remove-Item -LiteralPath $TempRoot -Recurse -Force
    }
}
