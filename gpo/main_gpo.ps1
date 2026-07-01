# =============================================================
# main_gpo.ps1 - Orchestrateur des GPO + permissions (III.2)
#   Wallpaper -> Drive Maps -> Slack -> OpenOffice -> Permissions NTFS.
#
#   Lance d'ABORD la preparation (prep\main_prep.ps1) : c'est idempotent,
#   donc si les OU/groupes/disques/dossiers existent deja rien n'est recree.
#   -> Tu peux donc tout faire en lancant juste ce script.
# A lancer en admin sur SRV-ADMIN.
# =============================================================
$ScriptDir = "$PSScriptRoot"

# --- 0) Preparation (OU, groupes, disques D:/E:, dossiers, partages) --------
Write-Host "[0] Preparation prealable (prep\main_prep.ps1)..." -ForegroundColor Cyan
& "$ScriptDir\..\prep\main_prep.ps1"

# Garde-fou : sans D: ET E:, les dossiers/permissions ne peuvent pas exister.
# (Cas Azure : disque temporaire pas encore libere -> un reboot est requis.)
$dOk = Get-Volume -DriveLetter D -ErrorAction SilentlyContinue
$eOk = Get-Volume -DriveLetter E -ErrorAction SilentlyContinue
if (-not $dOk -or -not $eOk) {
    Write-Host "`n[STOP] D: et/ou E: manquent encore." -ForegroundColor Red
    Write-Host "Sur Azure : REDEMARRE la VM (Restart-Computer) puis relance main_gpo.ps1." -ForegroundColor Red
    Write-Host "Sinon : verifie que 2 disques data sont bien attaches a la VM." -ForegroundColor Red
    return
}

# --- 1..5) GPO + permissions ------------------------------------------------
Write-Host "[1/5] GPO fond d'ecran..."       -ForegroundColor Cyan; & "$ScriptDir\01_GPO_Wallpaper.ps1"
Write-Host "[2/5] GPO drive maps..."         -ForegroundColor Cyan; & "$ScriptDir\02_GPO_DriveMaps.ps1"
Write-Host "[3/5] GPO Slack (obligatoire)..."-ForegroundColor Cyan; & "$ScriptDir\03_GPO_Slack.ps1"
Write-Host "[4/5] GPO OpenOffice (option)..."-ForegroundColor Cyan; & "$ScriptDir\04_GPO_OpenOffice.ps1"
Write-Host "[5/5] Permissions NTFS..."       -ForegroundColor Cyan; & "$ScriptDir\05_FolderPermissions.ps1"
Write-Host "`nGPO + permissions termine. Etape suivante : siem\main_siem.ps1" -ForegroundColor Magenta
