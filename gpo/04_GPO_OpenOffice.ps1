# =============================================================
# 04_GPO_OpenOffice.ps1 - GPO "OpenOffice deployment IF REQUIRED by each user" (III.2)
#   Contrairement a Slack (obligatoire), OpenOffice est OPTIONNEL par utilisateur.
#   On modelise le "si l'utilisateur le demande" par un FILTRAGE DE SECURITE :
#   la GPO ne s'applique qu'aux membres du groupe "OpenOfficeUsers".
#   -> Pour donner OpenOffice a un user : Add-ADGroupMember OpenOfficeUsers <user>.
# =============================================================
. "$PSScriptRoot\..\helpers.ps1"
. "$PSScriptRoot\..\config.ps1"
Test-Admin
Import-Module GroupPolicy -ErrorAction Stop

# 1) Groupe "a la demande" (ceux qui veulent OpenOffice y sont ajoutes)
if (-not (Get-ADGroup -Filter "Name -eq 'OpenOfficeUsers'" -ErrorAction SilentlyContinue)) {
    New-ADGroup -Name "OpenOfficeUsers" -GroupScope Global -GroupCategory Security `
        -Path $OU_Workspace -Description "Utilisateurs ayant demande OpenOffice (filtrage GPO)."
    Write-Host "Groupe 'OpenOfficeUsers' cree." -ForegroundColor Green
}

$Installer = Get-Input "Chemin UNC de l'installeur OpenOffice (MSI)" `
    "OpenOffice" "\\$Domain\SYSVOL\$Domain\installers\OpenOffice.msi"

# 2) Script de logon (idempotent : n'installe pas si deja present)
$body = @"
`$ErrorActionPreference = 'SilentlyContinue'
`$installed = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall' |
    ForEach-Object { (Get-ItemProperty `$_.PSPath).DisplayName } | Where-Object { `$_ -like '*OpenOffice*' }
if (-not `$installed) {
    Start-Process msiexec.exe -ArgumentList '/i','"$Installer"','/qn','/norestart' -Wait
}
"@

$GpoName = "OpenOffice - Deploiement optionnel"
New-LogonScriptGpo $GpoName "Install-OpenOffice.ps1" $body @($OU_Workspace, $OU_Administration)

# 3) Filtrage de securite : la GPO ne s'applique QU'AUX membres d'OpenOfficeUsers.
#    - OpenOfficeUsers : Apply (lecture + application)
#    - Authenticated Users : on retire l'application (sinon tout le monde l'aurait)
#    - Domain Computers : lecture (requis pour le traitement cote client, MS16-072)
Set-GPPermission -Name $GpoName -TargetName "OpenOfficeUsers"    -TargetType Group -PermissionLevel GpoApply -Replace | Out-Null
Set-GPPermission -Name $GpoName -TargetName "Domain Computers"   -TargetType Group -PermissionLevel GpoRead        | Out-Null
Set-GPPermission -Name $GpoName -TargetName "Authenticated Users" -TargetType Group -PermissionLevel None          | Out-Null
Write-Host "Filtrage de securite applique (seuls les membres d'OpenOfficeUsers recoivent la GPO)." -ForegroundColor Green

# --- VERIFICATION ---
Write-Host "`n[VERIFICATION] Filtrage de securite de la GPO :" -ForegroundColor Cyan
Get-GPPermission -Name $GpoName -All |
    Select-Object @{N='Trustee';E={$_.Trustee.Name}}, Permission | Format-Table -AutoSize
