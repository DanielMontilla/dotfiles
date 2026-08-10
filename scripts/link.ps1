<#
.SYNOPSIS
Links config files for a profile using dotbot. PowerShell counterpart of
scripts/link - the Windows entrypoint (no bash needed).

.DESCRIPTION
Usage (PowerShell):
    .\scripts\link.ps1 <profile>

If the dotbot binary isn't on PATH (common on Windows - pip --user installs to
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
    & $dotbot.Source -d $RepoRoot -c $Config @args 2>&1 | Out-Host
    exit $LASTEXITCODE
}

# Find a working Python (same logic as install.ps1: 'py -3' first, because
# 'python' may be the Microsoft Store stub / install manager)
foreach ($cand in @(@{ Name = "py"; Args = @("-3") }, @{ Name = "python"; Args = @() }, @{ Name = "python3"; Args = @() })) {
    $cmd = Get-Command $cand.Name -ErrorAction SilentlyContinue
    if (-not $cmd) { continue }
    $candArgs = $cand.Args
    $out = & $cmd.Source @candArgs -c "import sys;print(sys.version_info[0],sys.version_info[1])" 2>&1
    $line = ($out | Select-Object -Last 1)
    if ($null -eq $line -or $line.ToString().Trim() -notmatch "^\d+ \d+$") { continue }

    $out = & $cmd.Source @candArgs -c "import dotbot" 2>&1
    if ($LASTEXITCODE -eq 0 -and -not $out) {
        Write-Host "dotbot binary not found on PATH - using '$($cand.Name) -m dotbot'"
        & $cmd.Source @candArgs -m dotbot -d $RepoRoot -c $Config @args 2>&1 | Out-Host
        exit $LASTEXITCODE
    }
}

Write-Host "Error: dotbot is not installed." -ForegroundColor Red
Write-Host "Run: .\scripts\install.ps1 $Profile   (installs dotbot via pip)"
exit 1
