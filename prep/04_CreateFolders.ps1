# =============================================================
# 04_CreateFolders.ps1 - Cree l'arborescence de dossiers + partages SMB (III.1)
#   D:\WorkPlan  D:\Management  E:\HumanResources  E:\Estimate  E:\Client
# Le partage SMB est necessaire pour l'acces reseau et les drive maps (III.2).
# A lancer apres 03_InitDisks.ps1.
# =============================================================
. "$PSScriptRoot\..\helpers.ps1"
. "$PSScriptRoot\..\config.ps1"
Test-Admin

foreach ($f in $Folders) {
    # Le disque cible doit exister (D: ou E:)
    $drive = $f.Path.Substring(0, 2)   # "D:" / "E:"
    if (-not (Get-Volume -DriveLetter $drive[0] -ErrorAction SilentlyContinue)) {
        Write-Host "Disque $drive absent : lance d'abord 03_InitDisks.ps1. ($($f.Path) ignore)" -ForegroundColor Red
        continue
    }
    New-Item -ItemType Directory -Path $f.Path -Force | Out-Null
    Write-Host "Dossier '$($f.Path)' cree." -ForegroundColor Green
    Publish-Share $f.Path $f.Share
}

# --- VERIFICATION : dossiers + partages ---
Write-Host "`n[VERIFICATION] Dossiers crees :" -ForegroundColor Cyan
$Folders | ForEach-Object { Get-Item $_.Path -ErrorAction SilentlyContinue } |
    Select-Object FullName | Format-Table -AutoSize
Write-Host "[VERIFICATION] Partages SMB :" -ForegroundColor Cyan
Get-SmbShare | Where-Object { $_.Name -in $Folders.Share } |
    Select-Object Name, Path | Format-Table -AutoSize
