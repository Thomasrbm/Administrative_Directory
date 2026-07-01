# =============================================================
# main_workshop.ps1
# Description : Script principal pour le SERVEUR WORKSHOP
#               Lance tous les scripts dans le bon ordre
#               1. Installe AD DS
#               2. Rejoint la foret existante
#               3. Cree le dossier partage workshop
#               4. Cree le compte worker
# =============================================================

. "$PSScriptRoot\helpers.ps1"
Test-Admin

$ScriptDir = "$PSScriptRoot"

# Etape 1 : Installation AD DS
Write-Host "[1/2] Installation AD DS..." -ForegroundColor Cyan
& "$ScriptDir\ADPackageInstallor.ps1"

# Etape 2 : Rejoindre la foret existante (la promotion redemarre le serveur elle-meme)
Write-Host "[2/2] Connexion a la foret (la promotion redemarre le serveur)..." -ForegroundColor Cyan
& "$ScriptDir\JoinExistingDomainController.ps1"
