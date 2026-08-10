<#
.SYNOPSIS
Links config files for a profile using dotbot. PowerShell counterpart of
scripts/link — the Windows entrypoint (no bash needed).

.DESCRIPTION
Usage (PowerShell):
    .\scripts\link.ps1 <profile>

If the dotbot binary isn't on PATH (common on Windows — pip --user installs to
a Scripts dir that's often not on PATH), falls back to 'python -m dotbot'.
#>
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Profile
)

$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$Config = Join-Path $RepoRoot "profiles\$Profile\dotbot.yaml"

if (-not (Test-Path $Config -PathType Leaf)) {
    Write-Error "Config file '$Config' does not exist."
    exit 1
}

Write-Host "Using profile: $Profile"
Write-Host "Using config: $Config"

# Prefer the dotbot binary; fall back to 'python -m dotbot'
$dotbot = Get-Command dotbot -ErrorAction SilentlyContinue
if ($dotbot) {
    & $dotbot.Source -d $RepoRoot -c $Config @args
    exit $LASTEXITCODE
}

foreach ($pyName in @("python", "python3")) {
    $py = Get-Command $pyName -ErrorAction SilentlyContinue
    if (-not $py) { continue }
    & $py.Source -c "import dotbot" 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "dotbot binary not found on PATH — using '$pyName -m dotbot'"
        & $py.Source -m dotbot -d $RepoRoot -c $Config @args
        exit $LASTEXITCODE
    }
}

Write-Host "Error: dotbot is not installed." -ForegroundColor Red
Write-Host "Run: .\scripts\install.ps1 $Profile   (installs dotbot via pip)"
exit 1
