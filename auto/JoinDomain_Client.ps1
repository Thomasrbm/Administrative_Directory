# =============================================================
# JoinDomain_Client.ps1
# Description : Fait rejoindre une workstation Windows 10 au domaine
# Parametres  : - DomainName : nom du domaine (ex: domolia.local)
# =============================================================

. "$PSScriptRoot\helpers.ps1"
Test-Admin

# Popup : Demande du nom du domaine
$Domain = Get-Input "Entrez le nom du domaine a rejoindre (ex: domolia.local)" "Domaine" "domolia.local"

# Demande des credentials du Domain Admin
$Creds = Get-Credential -Message "Entrez les credentials d'un administrateur du domaine $Domain"

try {
    Add-Computer -DomainName $Domain -Credential $Creds -Force
    Write-Host "Jonction au domaine $Domain reussie." -ForegroundColor Green
    Write-Host "Lance 'Restart-Computer' quand tu es pret a redemarrer." -ForegroundColor Yellow
} catch {
    Write-Host "Erreur lors de la jonction : $_" -ForegroundColor Red
}
