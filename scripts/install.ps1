<#
.SYNOPSIS
Installs a profile. PowerShell counterpart of scripts/install - the Windows
entrypoint (no bash needed).

.DESCRIPTION
Usage (PowerShell):
    .\scripts\install.ps1 <profile>

Windows profiles (no nix) have nothing to install - this checks that Python
3.7+ is available and that dotbot is installed (pip-installing it if missing).
Nix profiles are rejected with a pointer to the bash scripts, since they need
Nix on a Linux/WSL machine.
#>
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Profile
)

$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$ProfileDir = Join-Path $RepoRoot "profiles\$Profile"

if (-not (Test-Path $ProfileDir -PathType Container)) {
    Write-Error "Profile directory '$ProfileDir' does not exist."
    exit 1
}

# Determine mode from marker files
$Mode = $null
if (Test-Path (Join-Path $ProfileDir ".nixos")) { $Mode = "nixos" }
elseif (Test-Path (Join-Path $ProfileDir ".nix-profile")) { $Mode = "nix-profile" }
elseif (Test-Path (Join-Path $ProfileDir ".windows")) { $Mode = "windows" }
else {
    Write-Error "Cannot determine mode for profile '$Profile' (missing .nixos, .nix-profile, or .windows marker)."
    exit 1
}

Write-Host "Using profile: $Profile (mode: $Mode)"

if ($Mode -ne "windows") {
    Write-Error "Profile '$Profile' is a $Mode profile - it needs Nix on a Linux/WSL machine. Use the bash scripts (./scripts/install $Profile) there."
    exit 1
}

Write-Host "Profile '$Profile' is a Windows profile (no nix)."
Write-Host "Checking prerequisites (dotbot needs Python 3.7+)..."

# Locate a working Python 3 interpreter.
# Candidate order:
#   1. 'py -3'  - the Windows launcher: finds the real install even when
#                'python' is the Microsoft Store stub / install manager
#   2. 'python' - python.org install with "Add python.exe to PATH"
#   3. 'python3'
# The version check output must look like "3 12"; anything else (e.g. the
# Store stub printing "Python install manager was updated") is rejected.
$pyExe = $null
$pyArgs = @()
$major = 0
$minor = 0

foreach ($cand in @(@{ Name = "py"; Args = @("-3") }, @{ Name = "python"; Args = @() }, @{ Name = "python3"; Args = @() })) {
    $cmd = Get-Command $cand.Name -ErrorAction SilentlyContinue
    if (-not $cmd) { continue }
    $candArgs = $cand.Args
    $out = & $cmd.Source @candArgs -c "import sys;print(sys.version_info[0],sys.version_info[1])" 2>&1
    $line = ($out | Select-Object -Last 1)
    if ($null -ne $line -and $line.ToString().Trim() -match "^\d+ \d+$") {
        $pyExe = $cmd.Source
        $pyArgs = $cand.Args
        $verOut = $line.ToString().Trim()
        $verParts = $verOut -split "\s+"
        $major = [int]$verParts[0]
        $minor = [int]$verParts[1]
        break
    }
}

if (-not $pyExe) {
    Write-Error "Python 3.7+ is required for dotbot but no working interpreter was found. Install it from https://www.python.org/downloads/ (tick 'Add python.exe to PATH') or run: winget install Python.Python.3.12"
    exit 1
}

if ($major -lt 3 -or ($major -eq 3 -and $minor -lt 7)) {
    Write-Error "Found Python $major.$minor, but dotbot requires Python 3.7 or newer."
    exit 1
}
Write-Host "  Python $major.$minor found ($pyExe)."

# Check dotbot: binary on PATH, or importable as a module
$hasDotbot = $false
if (Get-Command dotbot -ErrorAction SilentlyContinue) {
    $hasDotbot = $true
} else {
    $out = & $pyExe @pyArgs -c "import dotbot" 2>&1
    if ($LASTEXITCODE -eq 0 -and -not $out) { $hasDotbot = $true }
}

if ($hasDotbot) {
    Write-Host "  dotbot already available."
} else {
    Write-Host "  dotbot not found - installing it with pip..."
    & $pyExe @pyArgs -m pip install --user dotbot 2>&1 | Out-Host
    if ($LASTEXITCODE -ne 0) {
        Write-Error "pip install dotbot failed (exit $LASTEXITCODE)."
        exit 1
    }
}

Write-Host "Done. Link config files with: .\scripts\link.ps1 $Profile"
