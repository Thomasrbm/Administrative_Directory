# =============================================================
# 03_GPO_Slack.ps1 - GPO "Slack non-optional installation for each new user" (III.2)
#   GPO liee aux DEUX OU => s'applique a TOUS les utilisateurs (obligatoire).
#   A la connexion, un script installe Slack s'il n'est pas deja present.
#   Depose au prealable le MSI Slack dans un partage lisible par tous
#   (ex: SYSVOL) et donne son chemin UNC ci-dessous.
# =============================================================
. "$PSScriptRoot\..\helpers.ps1"
. "$PSScriptRoot\..\config.ps1"
Test-Admin

$Msi = Get-Input "Chemin UNC du MSI Slack (obligatoire pour tous)" `
    "Slack MSI" "\\$Domain\SYSVOL\$Domain\installers\SlackSetup.msi"

# Corps du script de logon (execute chez chaque utilisateur a la connexion).
# Garde-fou : ne reinstalle pas si Slack est deja la (idempotent).
$body = @"
`$ErrorActionPreference = 'SilentlyContinue'
`$installed = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall' |
    ForEach-Object { (Get-ItemProperty `$_.PSPath).DisplayName } | Where-Object { `$_ -like '*Slack*' }
if (-not `$installed -and -not (Test-Path "`$env:LOCALAPPDATA\slack")) {
    Start-Process msiexec.exe -ArgumentList '/i','"$Msi"','/qn','/norestart' -Wait
}
"@

New-LogonScriptGpo "Slack - Installation obligatoire" "Install-Slack.ps1" $body @($OU_Workspace, $OU_Administration)

# --- VERIFICATION ---
Write-Host "`n[VERIFICATION] Lien(s) et etat de la GPO Slack :" -ForegroundColor Cyan
(Get-GPO -Name "Slack - Installation obligatoire") | Select-Object DisplayName, GpoStatus, Id | Format-List
Write-Host "Test client : deposer le MSI, gpupdate /force, re-login -> Slack s'installe." -ForegroundColor Yellow
