# =============================================================
# main_admin.ps1
# Description : Script principal pour le SERVEUR ADMINISTRATEUR
#               Lance tous les scripts dans le bon ordre
#               1. Installe AD DS
#               2. Cree la foret
#               3. Cree les dossiers partages
#               4. Cree le compte administrateur
# =============================================================

$ScriptDir = "$PSScriptRoot"

# Etape 1 : Installation AD DS
Write-Host "[1/2] Installation AD DS..." -ForegroundColor Cyan
& "$ScriptDir\ADPackageInstallor.ps1"



# Etape 2 : Creation de la foret
Write-Host "[2/2] Creation de la foret : reponds aux fenetres popup (Alt+Tab si cachees)..." -ForegroundColor Cyan
& "$ScriptDir\CreateNewForestDomainController.ps1"



Write-Host "Le serveur va redemarrer. Relancez main_admin_post.ps1 apres le redemarrage." -ForegroundColor Magenta
