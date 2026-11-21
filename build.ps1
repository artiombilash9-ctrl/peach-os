#Requires -Version 5.1
<#
.SYNOPSIS
    Costruisce la ISO di Peach OS dentro WSL.

.DESCRIPTION
    Prepara (solo la prima volta) un ambiente Debian 13 isolato in /srv/peach-build,
    sincronizza il progetto, esegue live-build e copia la ISO in .\dist.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\build.ps1
#>
[CmdletBinding()]
param(
    [string]$Distro = 'Ubuntu'
)

$ErrorActionPreference = 'Stop'
$Project = Split-Path -Parent $MyInvocation.MyCommand.Path
$EnvDir = '/srv/peach-build'

function Invoke-Wsl {
    param([Parameter(Mandatory)][string[]]$Command)
    & wsl -d $Distro -u root -- @Command
    if ($LASTEXITCODE -ne 0) {
        throw "Comando WSL fallito (exit $LASTEXITCODE): $($Command -join ' ')"
    }
}

function Get-WslPath {
    param([Parameter(Mandatory)][string]$WindowsPath)
    $result = & wsl -d $Distro -u root -- wslpath -a $WindowsPath
    if ($LASTEXITCODE -ne 0) { throw "wslpath ha fallito per $WindowsPath" }
    return ($result | Out-String).Trim()
}

Write-Host ''
Write-Host '  Peach OS 1.0 "Trixie"  --  build' -ForegroundColor Magenta
Write-Host '  ---------------------------------' -ForegroundColor DarkMagenta

if (-not (Test-Path (Join-Path $Project 'auto/config'))) {
    throw "auto/config non trovato: esegui lo script dalla radice del progetto."
}

# 1. Ambiente Debian 13
$envReady = (& wsl -d $Distro -u root -- bash -c "test -x $EnvDir/bin/bash && command -v lb >/dev/null 2>&1 && echo ok" 2>$null | Out-String)
if ($envReady -notmatch 'ok') {
    Write-Host '==> Preparo l''ambiente Debian 13 in WSL (prima volta, alcuni minuti)' -ForegroundColor Yellow
    Invoke-Wsl @('bash', (Get-WslPath (Join-Path $Project 'tools/setup-build-env.sh')))
}

# 2. Sincronizzazione progetto
Write-Host '==> Sincronizzo il progetto' -ForegroundColor Cyan
Invoke-Wsl @(
    'bash',
    (Get-WslPath (Join-Path $Project 'tools/sync-to-wsl.sh')),
    $Project
)

# 3. Build
Write-Host '==> Avvio live-build (puo'' richiedere 20-40 minuti)' -ForegroundColor Cyan
Invoke-Wsl @('bash', (Get-WslPath (Join-Path $Project 'tools/build-in-chroot.sh')))

# 4. Raccolta ISO
Write-Host '==> Copio la ISO in .\dist' -ForegroundColor Cyan
Invoke-Wsl @(
    'bash',
    (Get-WslPath (Join-Path $Project 'tools/collect-iso.sh')),
    (Join-Path $Project 'dist')
)

Write-Host ''
Write-Host '  Fatto: dist\PeachOS-1.0-amd64.iso' -ForegroundColor Green
Write-Host ''
