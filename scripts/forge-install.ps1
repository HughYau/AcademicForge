param(
    [string]$Tool = "",
    [string]$Skills = "",
    [string]$Path = "",
    [Alias('Registry')]
    [string]$RegistrySourcePath = "",
    [switch]$Help
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RegistrySource = if ($RegistrySourcePath) {
    $RegistrySourcePath
} elseif ($env:FORGE_REGISTRY_URL) {
    $env:FORGE_REGISTRY_URL
} else {
    "https://raw.githubusercontent.com/HughYau/AcademicForge/refs/heads/site-first/registry/skills.json"
}

function Show-Usage {
    Write-Host "Usage: .\forge-install.ps1 -Tool <claude|opencode|codex> -Skills <id1,id2,...> [-Path <dir>] [-Registry <path-or-url>]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Tool     Target tool: claude, opencode, or codex"
    Write-Host "  -Skills   Comma-separated skill IDs from the registry"
    Write-Host "  -Path     Custom install path (overrides -Tool default)"
    Write-Host "  -Registry Registry JSON file path or URL"
    Write-Host "  -Help     Show this help"
}

function Get-SkillRecord {
    param(
        [Parameter(Mandatory = $true)]$Registry,
        [Parameter(Mandatory = $true)][string]$SkillId
    )

    if ($Registry -is [string]) {
        $Registry = $Registry | ConvertFrom-Json
    } elseif ($Registry -is [System.Array] -and $Registry.Count -gt 0 -and $Registry[0] -is [string]) {
        $Registry = ($Registry -join "`n") | ConvertFrom-Json
    }

    $skills = if ($Registry.PSObject.Properties.Name -contains 'skills') {
        @($Registry.skills)
    } else {
        @($Registry)
    }

    foreach ($skill in $skills) {
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

function Invoke-GitCheckoutRef {
    param(
        [Parameter(Mandatory = $true)][string]$RepositoryPath,
        [string]$Ref = ""
    )

    if (-not $Ref) {
        return $true
    }

    $checkoutExitCode = Invoke-GitQuiet -C $RepositoryPath checkout --detach $Ref
    if ($checkoutExitCode -eq 0) {
        return $true
    }

    $fetchExitCode = Invoke-GitQuiet -C $RepositoryPath fetch --depth 1 origin $Ref
    if ($fetchExitCode -ne 0) {
        return $false
    }

    return (Invoke-GitQuiet -C $RepositoryPath checkout --detach FETCH_HEAD) -eq 0
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
    Write-Host "Loading skill registry..." -ForegroundColor Blue
    if (Test-Path -LiteralPath $RegistrySource) {
        Copy-Item -LiteralPath $RegistrySource -Destination $registryFile -Force
    } else {
        Invoke-WebRequest -Uri $RegistrySource -OutFile $registryFile
    }
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
                    $gitArgs = @('clone', '--depth', '1')
                    $gitArgs += @($skill.install.url, $target)
                    $exitCode = Invoke-GitQuiet @gitArgs
                    if ($exitCode -ne 0) {
                        throw "Failed to clone $($skill.install.url)"
                    }

                    if (-not (Invoke-GitCheckoutRef -RepositoryPath $target -Ref $skill.install.ref)) {
                        throw "Failed to checkout ref $($skill.install.ref)"
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
                        $cloneArgs = @('clone', '--depth', '1', '--filter=blob:none', '--sparse')
                        $cloneArgs += @($skill.install.url, $tmpDir)
                        $cloneExitCode = Invoke-GitQuiet @cloneArgs
                        if ($cloneExitCode -ne 0) {
                            throw "Failed to sparse-checkout $($skill.install.url)"
                        }

                        if (-not (Invoke-GitCheckoutRef -RepositoryPath $tmpDir -Ref $skill.install.ref)) {
                            throw "Failed to checkout ref $($skill.install.ref)"
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
