# JoinExistingDomainController.ps1 - Rejoint une foret AD existante (DC additionnel)
# Parametres : DomainAddress
. "$PSScriptRoot\helpers.ps1"
Test-Admin

$Domain = Get-Input "Adresse du domaine existant (ex: domolia.local)" "Domaine" "domolia.local"
$Creds  = Get-Credential -Message "Domain Admin de $Domain (ex: DOMOLIA\Administrateur)"
# DSRM saisi via un pop-up masque (pas en clair dans le terminal)
$DSRM   = Get-PasswordInput "Mot de passe DSRM (Safe Mode)" "Mot de passe DSRM"

Write-Host "Promotion en cours (plusieurs minutes, le serveur redemarrera tout seul)..." -ForegroundColor Yellow
Import-Module ADDSDeployment

# Commande identique a celle generee par l'assistant GUI (Server Manager -> Afficher le script).
# IMPORTANT : avec la continuation de ligne (backtick), AUCUN commentaire ne peut suivre le backtick,
#             sinon la continuation casse. Les explications sont donc ici, en legende :
#   -NoGlobalCatalog:$false         : GC = ce DC partage les infos sur les autres DC (catalogue global)
#   -CriticalReplicationOnly:$false : replication complete (et pas seulement les donnees critiques)
#   -InstallDns:$true               : installe le role DNS
#   -NoRebootOnCompletion:$false    : le serveur redemarrera automatiquement a la fin
Install-ADDSDomainController `
    -DomainName $Domain `
    -Credential $Creds `
    -SafeModeAdministratorPassword $DSRM `
    -SiteName "Default-First-Site-Name" `
    -DatabasePath "C:\Windows\NTDS" `
    -LogPath "C:\Windows\NTDS" `
    -SysvolPath "C:\Windows\SYSVOL" `
    -NoGlobalCatalog:$false `
    -CreateDnsDelegation:$false `
    -CriticalReplicationOnly:$false `
    -InstallDns:$true `
    -NoRebootOnCompletion:$false `
    -Force:$true
