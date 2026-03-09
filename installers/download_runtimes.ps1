# Download and extract bundled Python + Bun runtimes for Windows.
#
# Usage:
#   .\download_runtimes.ps1 -TargetDir <path>
#
# Optional parameters:
#   -PythonBuildTag   python-build-standalone release tag  (default: 20260303)
#   -PythonVersion    CPython version                       (default: 3.12.13)
#   -BunVersion       Bun version                           (default: latest)

param(
    [Parameter(Mandatory)][string]$TargetDir,
    [string]$PythonBuildTag = "20260303",
    [string]$PythonVersion  = "3.12.13",
    [string]$BunVersion     = "latest"
)

$ErrorActionPreference = "Stop"

$PythonBaseUrl = "https://github.com/astral-sh/python-build-standalone/releases/download/$PythonBuildTag"
$BunBaseUrl    = "https://github.com/oven-sh/bun/releases"

# Resolve filenames
$PythonTriple   = "x86_64-pc-windows-msvc"
$PythonFilename = "cpython-${PythonVersion}+${PythonBuildTag}-${PythonTriple}-install_only.tar.gz"
$PythonUrl      = "$PythonBaseUrl/$PythonFilename"

if ($BunVersion -eq "latest") {
    $BunUrl = "$BunBaseUrl/latest/download/bun-windows-x64.zip"
} else {
    $BunUrl = "$BunBaseUrl/download/bun-v${BunVersion}/bun-windows-x64.zip"
}

New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null

# ── Download & extract Python ─────────────────────────────────

Write-Host "-> Downloading Python $PythonVersion (windows-x64) ..."
$TmpPython = New-TemporaryFile
$TmpPythonGz = "$TmpPython.tar.gz"
Rename-Item $TmpPython $TmpPythonGz
Invoke-WebRequest -Uri $PythonUrl -OutFile $TmpPythonGz -UseBasicParsing -MaximumRetryCount 3

Write-Host "-> Extracting Python to $TargetDir\python ..."
$PythonDir = Join-Path $TargetDir "python"
New-Item -ItemType Directory -Force -Path $PythonDir | Out-Null

# tar on Windows can handle .tar.gz
tar -xzf $TmpPythonGz -C $PythonDir --strip-components=1
Remove-Item $TmpPythonGz -Force

$PythonBin = Join-Path $PythonDir "python.exe"
if (-Not (Test-Path $PythonBin)) {
    Write-Error "Python binary not found at $PythonBin"
    Get-ChildItem $PythonDir | Format-Table
    exit 1
}
$pyVer = & $PythonBin --version 2>&1
Write-Host "  OK Python: $pyVer"

# ── Download & extract Bun ────────────────────────────────────

Write-Host "-> Downloading Bun (windows-x64) ..."
$TmpBun = New-TemporaryFile
$TmpBunZip = "$TmpBun.zip"
Rename-Item $TmpBun $TmpBunZip
Invoke-WebRequest -Uri $BunUrl -OutFile $TmpBunZip -UseBasicParsing -MaximumRetryCount 3

Write-Host "-> Extracting Bun to $TargetDir\bun ..."
$BunDir = Join-Path $TargetDir "bun"
New-Item -ItemType Directory -Force -Path $BunDir | Out-Null

$TmpExtract = Join-Path ([System.IO.Path]::GetTempPath()) "bun_extract"
if (Test-Path $TmpExtract) { Remove-Item $TmpExtract -Recurse -Force }
Expand-Archive -Path $TmpBunZip -DestinationPath $TmpExtract -Force

# Find bun.exe in extracted contents
$BunExe = Get-ChildItem -Path $TmpExtract -Recurse -Filter "bun.exe" | Select-Object -First 1
if (-Not $BunExe) {
    Write-Error "bun.exe not found in extracted archive"
    exit 1
}
Copy-Item $BunExe.FullName (Join-Path $BunDir "bun.exe") -Force
Remove-Item $TmpBunZip -Force
Remove-Item $TmpExtract -Recurse -Force

$BunBin = Join-Path $BunDir "bun.exe"
$bunVer = & $BunBin --version 2>&1
Write-Host "  OK Bun: $bunVer"

# ── Summary ───────────────────────────────────────────────────

Write-Host ""
Write-Host "Runtimes installed to $TargetDir"
Write-Host "Done."
