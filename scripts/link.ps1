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

# Run a native command without letting stderr trip $ErrorActionPreference.
# (Windows PowerShell 5.1 wraps native stderr in NativeCommandError and
# terminates on it when EAP is Stop - even with 2>&1 / 2>$null.) Returns the
# merged stdout+stderr output; check $LASTEXITCODE afterwards.
# NOTE: always pass the full argument list as one array - a bare "-c" token
# next to the call is treated as a parameter name and silently dropped.
function Invoke-Native {
    param([string]$FilePath, [string[]]$Arguments)
    $old = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        & $FilePath @Arguments 2>&1
    } finally {
        $ErrorActionPreference = $old
    }
}

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
    Invoke-Native $dotbot.Source @(@("-d", $RepoRoot, "-c", $Config) + $args) | Out-Host
    exit $LASTEXITCODE
}

# Find a working Python (same logic as install.ps1: 'py -3' first, because
# 'python' may be the Microsoft Store stub / install manager)
$candidates = @(
    @{ Name = "py"; Args = @("-3") },
    @{ Name = "python"; Args = @() },
    @{ Name = "python3"; Args = @() }
)

foreach ($cand in $candidates) {
    $cmd = Get-Command $cand.Name -ErrorAction SilentlyContinue
    if (-not $cmd) { continue }
    $candArgs = $cand.Args
    $out = Invoke-Native $cmd.Source @($candArgs + @("-c", "import sys;print(sys.version_info[0],sys.version_info[1])"))
    # scan the merged output for a line that actually looks like "3 12"
    $verLine = $null
    foreach ($l in $out) {
        if ($l.ToString().Trim() -match "^\d+ \d+$") { $verLine = $l.ToString().Trim(); break }
    }
    if ($null -eq $verLine) { continue }

    $out = Invoke-Native $cmd.Source @($candArgs + @("-c", "import dotbot"))
    if ($LASTEXITCODE -eq 0 -and -not $out) {
        Write-Host "dotbot binary not found on PATH - using '$($cand.Name) -m dotbot'"
        Invoke-Native $cmd.Source @($candArgs + @("-m", "dotbot", "-d", $RepoRoot, "-c", $Config) + $args) | Out-Host
        exit $LASTEXITCODE
    }
}

Write-Host "Error: dotbot is not installed." -ForegroundColor Red
Write-Host "Run: .\scripts\install.ps1 $Profile   (installs dotbot via pip)"
exit 1
