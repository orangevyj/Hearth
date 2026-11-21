# Compiles packaging\windows\hearth.iss into dist\hearth-<version>-setup.exe.
# Needs Inno Setup 6 installed on Windows (https://jrsoftware.org/isdl.php).
[CmdletBinding()]
param([string]$Version = "")

$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent (Split-Path -Parent $here)

if (-not $Version) {
    $match = Select-String -Path (Join-Path $root "pyproject.toml") -Pattern '^version = "(.*)"'
    if ($match) { $Version = $match.Matches[0].Groups[1].Value } else { $Version = "0.0.0" }
}

$iscc = @(
    (Join-Path ${env:ProgramFiles(x86)} "Inno Setup 6\ISCC.exe"),
    (Join-Path $env:ProgramFiles "Inno Setup 6\ISCC.exe")
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $iscc) {
    throw "Inno Setup 6 not found. Install it from https://jrsoftware.org/isdl.php and re-run."
}

Write-Host "==> compiling Hearth $Version"
& $iscc "/DVersion=$Version" "/DSourceRoot=$root" (Join-Path $here "hearth.iss")
if ($LASTEXITCODE -ne 0) { throw "ISCC failed with exit code $LASTEXITCODE" }
Write-Host "==> done: $root\dist\hearth-$Version-setup.exe"
