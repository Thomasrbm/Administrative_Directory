# =============================================================
# main_prep.ps1 - Orchestrateur de la PREPARATION (III.1)
#   Enchaine : OU -> groupes -> disques -> dossiers/partages -> users -> RDP.
# A lancer en admin sur SRV-ADMIN, une fois la foret domolia.local en place.
# =============================================================
$ScriptDir = "$PSScriptRoot"
Write-Host "[1/6] Creation des OU..."       -ForegroundColor Cyan; & "$ScriptDir\01_CreateOUs.ps1"
Write-Host "[2/6] Creation des groupes..."  -ForegroundColor Cyan; & "$ScriptDir\02_CreateGroups.ps1"
Write-Host "[3/6] Preparation des disques..."-ForegroundColor Cyan; & "$ScriptDir\03_InitDisks.ps1"
Write-Host "[4/6] Creation des dossiers..." -ForegroundColor Cyan; & "$ScriptDir\04_CreateFolders.ps1"
Write-Host "[5/6] Creation des users de test..." -ForegroundColor Cyan; & "$ScriptDir\05_CreateTestUsers.ps1"
Write-Host "[6/6] Autorisation RDP des users..." -ForegroundColor Cyan; & "$ScriptDir\06_EnableRemoteLogin.ps1"
Write-Host "`nPreparation terminee. Etape suivante : gpo\main_gpo.ps1" -ForegroundColor Magenta
