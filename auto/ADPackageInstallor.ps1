# ADPackageInstallor.ps1 - Installe AD DS et ses dependances
. "$PSScriptRoot\helpers.ps1"


Test-Admin

# --- AVANT : etat de la feature et de ses dependances avant l'operation ---
Write-Host "`n[AVANT] Etat d'AD DS et de ses dependances :" -ForegroundColor Cyan
Get-WindowsFeature AD-Domain-Services, RSAT-AD-Tools, RSAT-ADDS |
    Select-Object Name, InstallState | Format-Table -AutoSize

# ft windows  (commandlet (verbe + nom))   install une feature windows
# name = quelle fonction, ad - devient controlleur de domaine
# incluede ...  = pour avoir les outils de gestion (booleen), sinon peut rien manager
# Install-WindowsFeature est IDEMPOTENT : il n'installe QUE les dependances manquantes.
# Si tout est deja present -> ExitCode = NoChangeNeeded et il ne fait rien.
Write-Host "Installation d'AD DS en cours... (1 a 3 min sur une VM B-series, ne ferme pas la fenetre)" -ForegroundColor Yellow
$res = Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
Write-Host "Installation AD DS terminee." -ForegroundColor Green

# --- PREUVE : ce qui a REELLEMENT ete installe lors de cette execution ---
Write-Host "`n[PREUVE] Resultat de l'operation :" -ForegroundColor Cyan
Write-Host "Success  : $($res.Success)"
Write-Host "ExitCode : $($res.ExitCode)"   # 'NoChangeNeeded' = rien a faire, le script n'a rien installe
if ($res.FeatureResult.Count -eq 0) {
    Write-Host "Aucune feature ajoutee : tout etait deja installe (le script n'a rien fait)." -ForegroundColor Green
} else {
    Write-Host "Features reellement ajoutees cette fois (uniquement celles qui manquaient) :" -ForegroundColor Green
    $res.FeatureResult | Select-Object -ExpandProperty DisplayName
}

# --- VERIFICATION : la fonctionnalite AD DS est-elle bien installee ? ---
Write-Host "`n[VERIFICATION] Etat final de la fonctionnalite AD DS :" -ForegroundColor Cyan
Get-WindowsFeature AD-Domain-Services | Select-Object Name, InstallState | Format-Table -AutoSize
