# =============================================================
# 05_FolderPermissions.ps1 - Applique la MATRICE de permissions NTFS (III.2)
#   "Allow groups to access / edit / create / delete certain folders/files"
#
# Techniquement ce sont des ACL NTFS (pas une GPO au sens registre), c'est LA
# bonne facon de gerer des droits fichiers par groupe. La matrice complete est
# dans config.ps1 (lisible d'un coup d'oeil).
#
# Pour chaque dossier : on repart d'une ACL propre (heritage coupe, base SYSTEM
# + Administrateurs), puis on accorde a chaque groupe EXACTEMENT son niveau.
# A lancer apres prep\main_prep.ps1.
# =============================================================
. "$PSScriptRoot\..\helpers.ps1"
. "$PSScriptRoot\..\config.ps1"
Test-Admin

# On indexe la matrice par dossier -> { groupe = niveau } pour traiter dossier par dossier.
foreach ($f in $Folders) {
    $path = $f.Path
    if (-not (Test-Path $path)) {
        Write-Host "Dossier absent : $path (lance prep\04_CreateFolders.ps1). Ignore." -ForegroundColor Red
        continue
    }

    Write-Host "`n=== $path ===" -ForegroundColor Cyan
    Reset-FolderAcl $path   # table rase controlee

    foreach ($group in $Groups) {
        $level = $PermissionMatrix[$group][$path]
        if ($null -eq $level) {
            Write-Host "  [$group] -> aucun droit" -ForegroundColor DarkGray
            continue
        }
        Assert-GroupExists $group
        Grant-NtfsRight $path "$NetBIOS\$group" $level
    }
}

# --- VERIFICATION : relit l'ACL de chaque dossier (droits par groupe) ---
Write-Host "`n[VERIFICATION] Permissions effectives :" -ForegroundColor Cyan
foreach ($f in $Folders) {
    if (-not (Test-Path $f.Path)) { continue }
    Write-Host "`n$($f.Path) :" -ForegroundColor Yellow
    (Get-Acl $f.Path).Access |
        Where-Object { $_.IdentityReference -like "$NetBIOS\*" } |
        Select-Object IdentityReference, FileSystemRights, AccessControlType |
        Format-Table -AutoSize
}
