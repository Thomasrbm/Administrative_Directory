# =============================================================
# 02_EnableFolderAuditing.ps1 - Audit d'acces aux dossiers (III.3 / III.4)
#   Necessaire pour le script "isoler les acces/modifs d'un dossier" (EventID 4663).
#   Deux conditions : (1) sous-categorie "File System" activee,
#                     (2) une regle d'audit (SACL) posee sur chaque dossier.
# A lancer sur SRV-ADMIN, apres que les dossiers existent.
# =============================================================
. "$PSScriptRoot\..\helpers.ps1"
. "$PSScriptRoot\..\config.ps1"
Test-Admin

# (1) Sous-categorie Object Access > File System (genere les 4663)
auditpol /set /subcategory:"File System" /success:enable /failure:enable | Out-Null
Write-Host "Audit 'File System' active." -ForegroundColor Green

# (2) SACL sur chacun des 5 dossiers
foreach ($f in $Folders) {
    if (Test-Path $f.Path) {
        Enable-FolderAuditing $f.Path
    } else {
        Write-Host "Dossier absent : $($f.Path) (lance prep\04_CreateFolders.ps1). Ignore." -ForegroundColor Red
    }
}

# --- VERIFICATION : relit la SACL d'un dossier temoin ---
Write-Host "`n[VERIFICATION] Audit 'File System' :" -ForegroundColor Cyan
auditpol /get /subcategory:"File System" | Select-String "File System"
Write-Host "[VERIFICATION] SACL de $($Folders[0].Path) :" -ForegroundColor Cyan
(Get-Acl $Folders[0].Path -Audit).Audit |
    Select-Object IdentityReference, FileSystemRights, AuditFlags | Format-Table -AutoSize
