# =============================================================
# 02_CreateGroups.ps1 - Cree les 4 groupes de securite (III.1)
#   Worker, Direction, Secretary, Administrator
# Worker + Direction + Secretary -> OU Workspace (utilisateurs metiers)
# Administrator                   -> OU Administration (equipe d'admin)
# A lancer apres 01_CreateOUs.ps1.
# =============================================================
. "$PSScriptRoot\..\helpers.ps1"
. "$PSScriptRoot\..\config.ps1"
Test-Admin

# Placement de chaque groupe dans son OU
$Placement = @{
    "Worker"        = $OU_Workspace
    "Direction"     = $OU_Workspace
    "Secretary"     = $OU_Workspace
    "Administrator" = $OU_Administration
}

foreach ($g in $Groups) {
    $ou = $Placement[$g]
    if (Get-ADGroup -Filter "Name -eq '$g'" -ErrorAction SilentlyContinue) {
        Write-Host "Groupe '$g' existe deja." -ForegroundColor Yellow
    } else {
        New-ADGroup -Name $g -GroupScope Global -GroupCategory Security -Path $ou `
            -Description "Groupe metier '$g' (permissions dossiers via NTFS)."
        Write-Host "Groupe '$g' cree dans $ou." -ForegroundColor Green
    }
}

# --- VERIFICATION : relit les groupes crees ---
Write-Host "`n[VERIFICATION] Groupes de securite :" -ForegroundColor Cyan
foreach ($g in $Groups) {
    Get-ADGroup -Identity $g | Select-Object Name, GroupScope, DistinguishedName
}
