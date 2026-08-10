<#
.SYNOPSIS
Installs a profile. PowerShell counterpart of scripts/install — the Windows
entrypoint (no bash needed).

.DESCRIPTION
Usage (PowerShell):
    .\scripts\install.ps1 <profile>

Windows profiles (no nix) have nothing to install — this checks that Python
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
    Write-Error "Profile '$Profile' is a $Mode profile — it needs Nix on a Linux/WSL machine. Use the bash scripts (./scripts/install $Profile) there."
    exit 1
}

Write-Host "Profile '$Profile' is a Windows profile (no nix)."
Write-Host "Checking prerequisites (dotbot needs Python 3.7+)..."

# Locate a Python interpreter (python preferred, python3 as fallback)
$py = Get-Command python -ErrorAction SilentlyContinue
if (-not $py) { $py = Get-Command python3 -ErrorAction SilentlyContinue }
if (-not $py) {
    Write-Error "Python 3.7+ is required for dotbot but was not found. Install it from https://www.python.org/downloads/ and check 'Add python.exe to PATH'."
    exit 1
}

$verOut = & $py.Source -c "import sys; print('{}.{}'.format(sys.version_info.major, sys.version_info.minor))" 2>$null
if ($LASTEXITCODE -ne 0 -or -not $verOut) {
    Write-Error "Could not determine the Python version — is Python on PATH and working?"
    exit 1
}
$verOut = ($verOut | Select-Object -Last 1).Trim()
$verParts = $verOut -split "\."
$major = [int]$verParts[0]
$minor = [int]$verParts[1]

if ($major -lt 3 -or ($major -eq 3 -and $minor -lt 7)) {
    Write-Error "Found Python $verOut, but dotbot requires Python 3.7 or newer."
    exit 1
}
Write-Host "  Python $verOut found."

# Check dotbot: binary on PATH, or importable as a module
$hasDotbot = $false
if (Get-Command dotbot -ErrorAction SilentlyContinue) {
    $hasDotbot = $true
} else {
    & $py.Source -c "import dotbot" 2>$null
    if ($LASTEXITCODE -eq 0) { $hasDotbot = $true }
}

if ($hasDotbot) {
    Write-Host "  dotbot already available."
} else {
    Write-Host "  dotbot not found — installing it with pip..."
    & $py.Source -m pip install --user dotbot
}

Write-Host "Done. Link config files with: .\scripts\link.ps1 $Profile"
