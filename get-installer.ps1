<#
    FleetDeck Agent installer downloader.

    Detects the platform, downloads the matching installer and verifies its
    SHA-256 against the published checksums. It never runs the installer.

    Usage:
      powershell -NoProfile -ExecutionPolicy Bypass -File get-installer.ps1
      pwsh get-installer.ps1 -Destination $HOME/Downloads
#>
[CmdletBinding()]
param(
    [string]$Destination = "",
    [string]$Repository = "jobongriff123-lab/fleetdeck-agent-installer",
    [string]$Tag = "latest"
)

$ErrorActionPreference = "Stop"

$exeSha = "daaa8956ccb04d8f50aec2bb0cd39155e1ba223779588e785ba6931b154e0f4f"
$dmgSha = "0c24f2a4dea3b16a0540a931d25b26e40e04a9f94fd54e0f3801426db92013c0"

# ---- platform detection ------------------------------------------------
$onWindows = $true
$onMac = $false
$isWindowsVar = Get-Variable -Name IsWindows -Scope Global -ErrorAction SilentlyContinue
if ($isWindowsVar) {
    $onWindows = [bool]$global:IsWindows
    $onMac = [bool]$global:IsMacOS
}
elseif ($PSVersionTable.PSVersion.Major -ge 6) {
    $onWindows = [System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT
    $onMac = $false
}

if ($onWindows) {
    $asset = "Agengminiups.exe"
    $sha = $exeSha
    $howTo = "Run it with:  .\Agengminiups.exe /install"
}
elseif ($onMac) {
    $asset = "FleetDeck-Agent-Setup.dmg"
    $sha = $dmgSha
    $howTo = "Open the disk image and run the installer inside it."
}
else {
    throw "No installer is published for this platform. Windows and macOS builds exist."
}

if ([string]::IsNullOrWhiteSpace($Destination)) { $Destination = Join-Path (Get-Location) "FleetDeck" }
[void](New-Item -ItemType Directory -Path $Destination -Force)
$target = Join-Path $Destination $asset
if ($Tag -eq "latest") { $url = "https://github.com/$Repository/releases/latest/download/$asset" }
else { $url = "https://github.com/$Repository/releases/download/$Tag/$asset" }

Write-Host ("Downloading " + $asset + " from " + $url)
$curl = Get-Command curl.exe -ErrorAction SilentlyContinue
if ($curl) {
    & $curl.Source -fL --progress-bar -o $target $url
    if ($LASTEXITCODE -ne 0) { throw ("Download failed with exit code " + $LASTEXITCODE) }
}
else {
    Invoke-WebRequest -Uri $url -OutFile $target -UseBasicParsing
}

$hash = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToLowerInvariant()
if ($hash -ne $sha) {
    try { Remove-Item -LiteralPath $target -Force -ErrorAction SilentlyContinue } catch { }
    throw ("Checksum mismatch for " + $asset + ". Expected " + $sha + ", got " + $hash)
}

Write-Host ""
Write-Host ("Saved    : " + $target)
Write-Host ("Size     : {0:N0} bytes" -f (Get-Item -LiteralPath $target).Length)
Write-Host ("SHA-256 : " + $hash + "   (verified)")
Write-Host ""
Write-Host $howTo
