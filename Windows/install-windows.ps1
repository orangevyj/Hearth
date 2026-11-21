<#
  Hearth bootstrap for Windows.

  Finds or installs Python 3.12 (winget first, python.org installer as a
  fallback), creates .venv, installs Hearth and uv, writes hearth.cmd and
  optionally adds a Start-menu shortcut. Nothing machine-wide, no elevation.

  Usage (PowerShell, from the project folder):
      powershell -ExecutionPolicy Bypass -File scripts\install-windows.ps1 [-Start] [-SkipShortcut]
#>
[CmdletBinding()]
param(
    [switch]$Start,
    [switch]$SkipShortcut,
    [string]$PythonVersion = "3.12"
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $projectRoot

function Write-Step($message) { Write-Host "==> $message" -ForegroundColor Cyan }
function Write-Warn($message) { Write-Host "    $message" -ForegroundColor Yellow }

function Find-Python {
    # Returns a hashtable (exe plus fixed args) or $null. A hashtable avoids the
    # classic PowerShell trap where returning an array unrolls it and "py -3.12"
    # arrives as separate items.
    $candidates = @(
        @{ Exe = "py"; Args = @("-$PythonVersion") },
        @{ Exe = "python"; Args = @() },
        @{ Exe = "python3"; Args = @() }
    )
    foreach ($candidate in $candidates) {
        try {
            $out = & $candidate.Exe @($candidate.Args) -c "import sys; print('%d.%d' % sys.version_info[:2])" 2>$null
            if ($LASTEXITCODE -eq 0 -and "$out".Trim() -match "^3\.(1[2-9])") { return $candidate }
        } catch { }
    }
    $paths = @(
        (Join-Path $env:LOCALAPPDATA "Programs\Python\Python312\python.exe"),
        (Join-Path $env:ProgramFiles "Python312\python.exe"),
        "C:\Python312\python.exe"
    )
    foreach ($path in $paths) {
        if (Test-Path $path) { return @{ Exe = $path; Args = @() } }
    }
    return $null
}

function Invoke-Python {
    param($Python, [string[]]$Arguments)
    & $Python.Exe @($Python.Args) @Arguments
}

Write-Step "Hearth for Windows setup ($projectRoot)"

# --- 1. Python -------------------------------------------------------------------
$python = Find-Python
if (-not $python) {
    Write-Warn "Python $PythonVersion not found."
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Step "Installing Python $PythonVersion with winget"
        # --source winget matters: on some VMs the msstore source fails its
        # certificate check and winget then refuses to pick a package.
        try {
            winget install -e --id "Python.Python.$PythonVersion" --source winget --scope user `
                --accept-package-agreements --accept-source-agreements --disable-interactivity
        } catch {
            Write-Warn "winget could not install Python: $($_.Exception.Message)"
        }
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "User") + ";" + `
                    [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + $env:Path
        $python = Find-Python
    }
    if (-not $python) {
        Write-Step "Downloading the official Python $PythonVersion installer instead"
        $installer = Join-Path $env:TEMP "python-$PythonVersion-setup.exe"
        $download = "https://www.python.org/ftp/python/3.12.10/python-3.12.10-amd64.exe"
        Invoke-WebRequest $download -OutFile $installer
        Write-Step "Installing Python for the current user (no admin needed)"
        Start-Process -FilePath $installer -Wait -ArgumentList `
            "/quiet", "InstallAllUsers=0", "PrependPath=1", "Include_pip=1", "Include_launcher=1"
        $python = Find-Python
    }
}
if (-not $python) {
    throw "Python $PythonVersion still not found. Install it from python.org (tick 'Add python.exe to PATH') and re-run this script."
}
Write-Step "Using Python: $($python.Exe) $($python.Args -join ' ')"

# --- 2. virtualenv + dependencies -------------------------------------------------
$venv = Join-Path $projectRoot ".venv"
$venvPython = Join-Path $venv "Scripts\python.exe"
if (-not (Test-Path $venvPython)) {
    Write-Step "Creating the virtualenv"
    Invoke-Python -Python $python -Arguments @("-m", "venv", $venv)
}
if (-not (Test-Path $venvPython)) { throw "Could not create .venv at $venv" }

Write-Step "Installing Hearth and its Python dependencies"
& $venvPython -m pip install --upgrade pip --quiet
& $venvPython -m pip install -e . --quiet
Write-Step "Installing uv (builds the ComfyUI and Whisper runtimes later)"
& $venvPython -m pip install --upgrade uv --quiet

# --- 3. launcher -----------------------------------------------------------------
$cmdPath = Join-Path $projectRoot "hearth.cmd"
Write-Step "Writing $cmdPath"
@"
@echo off
rem Hearth launcher (created by scripts\install-windows.ps1)
"%~dp0.venv\Scripts\python.exe" -m hearth %*
"@ | Set-Content -Path $cmdPath -Encoding ASCII

if (-not $SkipShortcut) {
    Write-Step "Adding a Start-menu shortcut"
    $shortcutPath = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Hearth.lnk"
    try {
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = $cmdPath
        $shortcut.WorkingDirectory = $projectRoot
        $shortcut.Description = "Hearth - local AI workspace"
        $shortcut.Save()
    } catch {
        Write-Warn "Could not create the shortcut: $($_.Exception.Message)"
    }
}

Write-Step "Checking that the server imports"
& $venvPython -c "import hearth, fastapi, uvicorn, cryptography; print('hearth', hearth.__version__, 'imports cleanly')"

Write-Step "Done."
Write-Host "  Start it with:  $cmdPath"
Write-Host "  Data lives in:  $env:LOCALAPPDATA\Hearth"
Write-Host "  Models and runtimes download on first use from the launcher."

if ($Start) {
    Write-Step "Starting Hearth"
    Start-Process -FilePath $cmdPath
}
