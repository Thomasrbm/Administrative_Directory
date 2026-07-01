# =============================================================
# main_gpo.ps1 - Orchestrateur des GPO + permissions (III.2)
#   Wallpaper -> Drive Maps -> Slack -> OpenOffice -> Permissions NTFS.
# A lancer en admin sur SRV-ADMIN, apres prep\main_prep.ps1.
# =============================================================
$ScriptDir = "$PSScriptRoot"
Write-Host "[1/5] GPO fond d'ecran..."       -ForegroundColor Cyan; & "$ScriptDir\01_GPO_Wallpaper.ps1"
Write-Host "[2/5] GPO drive maps..."         -ForegroundColor Cyan; & "$ScriptDir\02_GPO_DriveMaps.ps1"
Write-Host "[3/5] GPO Slack (obligatoire)..."-ForegroundColor Cyan; & "$ScriptDir\03_GPO_Slack.ps1"
Write-Host "[4/5] GPO OpenOffice (option)..."-ForegroundColor Cyan; & "$ScriptDir\04_GPO_OpenOffice.ps1"
Write-Host "[5/5] Permissions NTFS..."       -ForegroundColor Cyan; & "$ScriptDir\05_FolderPermissions.ps1"
Write-Host "`nGPO + permissions termine. Etape suivante : siem\main_siem.ps1" -ForegroundColor Magenta
