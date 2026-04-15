param(
    [string]$Tool = "",
    [string]$Skills = "",
    [string]$Path = "",
    [switch]$Help
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RegistryUrl = if ($env:FORGE_REGISTRY_URL) {
    $env:FORGE_REGISTRY_URL
} else {
    "https://raw.githubusercontent.com/HughYau/AcademicForge/refs/heads/master/registry/skills.json"
}

function Show-Usage {
    Write-Host "Usage: .\forge-install.ps1 -Tool <claude|opencode|codex> -Skills <id1,id2,...> [-Path <dir>]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Tool     Target tool: claude, opencode, or codex"
    Write-Host "  -Skills   Comma-separated skill IDs from the registry"
    Write-Host "  -Path     Custom install path (overrides -Tool default)"
    Write-Host "  -Help     Show this help"
}

function Get-SkillRecord {
    param(
        [Parameter(Mandatory = $true)]$Registry,
        [Parameter(Mandatory = $true)][string]$SkillId
    )

    foreach ($skill in $Registry.skills) {
        if ($skill.id -eq $SkillId) {
            return $skill
        }

        if ($skill.PSObject.Properties.Match('sub_skills').Count -gt 0) {
            foreach ($subSkill in @($skill.sub_skills)) {
                if ($subSkill.id -eq $SkillId) {
                    return $subSkill
                }
            }
        }
    }

    return $null
}

function Invoke-GitQuiet {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)

    $stdoutFile = [System.IO.Path]::GetTempFileName()
    $stderrFile = [System.IO.Path]::GetTempFileName()

    try {
        $process = Start-Process -FilePath git -ArgumentList $Arguments -NoNewWindow -Wait -PassThru -RedirectStandardOutput $stdoutFile -RedirectStandardError $stderrFile
        return $process.ExitCode
    } finally {
        if (Test-Path -LiteralPath $stdoutFile) {
            Remove-Item -LiteralPath $stdoutFile -Force
        }
        if (Test-Path -LiteralPath $stderrFile) {
            Remove-Item -LiteralPath $stderrFile -Force
        }
    }
}

function Invoke-CleanAds {
    param([Parameter(Mandatory = $true)][string]$TargetDir)

    $cleanedCount = 0
    $files = Get-ChildItem -Path $TargetDir -Recurse -Filter "SKILL.md" -File -ErrorAction SilentlyContinue
    foreach ($file in $files) {
        $content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
        $updated = [System.Text.RegularExpressions.Regex]::Replace(
            $content,
            "\n+## Suggest Using K-Dense Web.*",
            "",
            [System.Text.RegularExpressions.RegexOptions]::Singleline
        )

        if ($updated -ne $content) {
            Set-Content -LiteralPath $file.FullName -Value $updated -NoNewline -Encoding UTF8
            $cleanedCount += 1
        }
    }

    if ($cleanedCount -gt 0) {
        Write-Host "  Cleaned ad sections from $cleanedCount file(s)" -ForegroundColor Yellow
    }
}

if ($Help) {
    Show-Usage
    exit 0
}

if (-not $Tool -or -not $Skills) {
    Write-Host "Error: -Tool and -Skills are required" -ForegroundColor Red
    Show-Usage
    exit 1
}

$InstallPath = $Path
if (-not $InstallPath) {
    switch ($Tool.ToLowerInvariant()) {
        "claude" { $InstallPath = ".claude\skills" }
        "opencode" { $InstallPath = ".opencode\skills" }
        "codex" { $InstallPath = ".codex\skills" }
        default {
            Write-Host "Error: unknown tool '$Tool'. Use claude, opencode, or codex." -ForegroundColor Red
            exit 1
        }
    }
}

try {
    $null = Invoke-GitQuiet --version
} catch {
    Write-Host "Error: 'git' is required but not installed." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "===============================================" -ForegroundColor Blue
Write-Host " Skill Configurator - Forge Installer" -ForegroundColor Blue
Write-Host "===============================================" -ForegroundColor Blue
Write-Host ""
Write-Host "Tool:   $Tool" -ForegroundColor Cyan
Write-Host "Skills: $Skills" -ForegroundColor Cyan
Write-Host "Path:   $InstallPath" -ForegroundColor Cyan
Write-Host ""

$registryFile = [System.IO.Path]::GetTempFileName()

try {
    Write-Host "Downloading skill registry..." -ForegroundColor Blue
    Invoke-WebRequest -Uri $RegistryUrl -OutFile $registryFile
    $registry = Get-Content -LiteralPath $registryFile -Raw -Encoding UTF8 | ConvertFrom-Json
    Write-Host "Registry loaded." -ForegroundColor Green
    Write-Host ""

    $null = New-Item -ItemType Directory -Path $InstallPath -Force

    $success = New-Object System.Collections.Generic.List[string]
    $failed = New-Object System.Collections.Generic.List[string]

    foreach ($rawId in ($Skills -split ',')) {
        $skillId = $rawId.Trim()
        if (-not $skillId) {
            continue
        }

        Write-Host "Installing: $skillId" -ForegroundColor Cyan
        $skill = Get-SkillRecord -Registry $registry -SkillId $skillId

        if (-not $skill) {
            Write-Host "  Skill '$skillId' not found in registry. Skipping." -ForegroundColor Red
            $failed.Add($skillId)
            continue
        }

        $target = Join-Path $InstallPath $skillId
        if (Test-Path -LiteralPath $target) {
            Remove-Item -LiteralPath $target -Recurse -Force
        }

        try {
            switch ($skill.install.method) {
                "git-clone" {
                    $exitCode = Invoke-GitQuiet clone --depth 1 $skill.install.url $target
                    if ($exitCode -ne 0) {
                        throw "Failed to clone $($skill.install.url)"
                    }

                    $gitDir = Join-Path $target ".git"
                    if (Test-Path -LiteralPath $gitDir) {
                        try {
                            Remove-Item -LiteralPath $gitDir -Recurse -Force
                        } catch {
                            Write-Host "  Warning: failed to remove .git metadata from $skillId." -ForegroundColor Yellow
                        }
                    }

                    Write-Host "  Cloned successfully." -ForegroundColor Green
                }
                "sparse-checkout" {
                    if (-not $skill.install.sparse_path) {
                        throw "sparse-checkout requires sparse_path"
                    }

                    $tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) ("forge-" + $skillId + "-" + [System.Guid]::NewGuid().ToString("N"))
                    try {
                        $cloneExitCode = Invoke-GitQuiet clone --depth 1 --filter=blob:none --sparse $skill.install.url $tmpDir
                        if ($cloneExitCode -ne 0) {
                            throw "Failed to sparse-checkout $($skill.install.url)"
                        }

                        $sparseExitCode = Invoke-GitQuiet -C $tmpDir sparse-checkout set $skill.install.sparse_path
                        if ($sparseExitCode -ne 0) {
                            throw "Failed to set sparse path $($skill.install.sparse_path)"
                        }

                        $sourcePath = Join-Path $tmpDir $skill.install.sparse_path
                        if (-not (Test-Path -LiteralPath $sourcePath)) {
                            throw "Sparse path '$($skill.install.sparse_path)' not found in repository"
                        }

                        $null = New-Item -ItemType Directory -Path $target -Force
                        $items = Get-ChildItem -LiteralPath $sourcePath -Force
                        foreach ($item in $items) {
                            Copy-Item -LiteralPath $item.FullName -Destination $target -Recurse -Force
                        }

                        Write-Host "  Sparse-checkout completed." -ForegroundColor Green
                    } finally {
                        if (Test-Path -LiteralPath $tmpDir) {
                            Remove-Item -LiteralPath $tmpDir -Recurse -Force
                        }
                    }
                }
                default {
                    throw "Unknown install method: $($skill.install.method)"
                }
            }

            if ($skill.post_install -contains "clean_ads") {
                Invoke-CleanAds -TargetDir $target
            }

            $success.Add($skillId)
        } catch {
            Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
            $failed.Add($skillId)
        }
    }

    Write-Host ""
    Write-Host "===============================================" -ForegroundColor Blue
    Write-Host " Installation Summary" -ForegroundColor Blue
    Write-Host "===============================================" -ForegroundColor Blue

    foreach ($skillId in $success) {
        Write-Host "  OK  $skillId" -ForegroundColor Green
    }

    foreach ($skillId in $failed) {
        Write-Host "  FAIL $skillId" -ForegroundColor Red
    }

    Write-Host ""
    Write-Host "Installed skill packs live under: $InstallPath" -ForegroundColor Cyan
} finally {
    if (Test-Path -LiteralPath $registryFile) {
        Remove-Item -LiteralPath $registryFile -Force
    }
}
