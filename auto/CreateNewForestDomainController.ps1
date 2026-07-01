# CreateNewForestDomainController.ps1 - Cree une nouvelle foret AD


# Parametres : DomainAddress, NetbiosName
. "$PSScriptRoot\helpers.ps1"


Test-Admin


$Domain  = Get-Input "Adresse du domaine (ex: domolia.local)" "Domaine" "domolia.local"
$Netbios = Get-Input "Nom NetBIOS (ex: DOMOLIA)" "NetBIOS" "DOMOLIA"



# DSRM = Directory Services Restore Mode (mdp de sauvetage)
# Saisi via un pop-up masque (le mdp ne s'affiche pas en clair, contrairement au terminal)
$DSRM    = Get-PasswordInput "Mot de passe DSRM (Directory Services Restore Mode)" "Mot de passe DSRM"


Write-Host "Creation de la foret en cours (plusieurs minutes, le serveur redemarrera tout seul)..." -ForegroundColor Yellow


Import-Module ADDSDeployment   # importe les cmdlets d'installation

# Commande identique a celle generee par l'assistant GUI (Server Manager -> Afficher le script).
# IMPORTANT : avec la continuation de ligne (backtick), AUCUN commentaire ne peut suivre le backtick,
#             sinon la continuation casse et le script plante. Les explications sont donc ici, en legende :
#   -DomainNetbiosName            : nom court (NetBIOS) du domaine
#   -SafeModeAdministratorPassword: mot de passe DSRM (saisi plus haut)
#   -ForestMode / -DomainMode     : "WinThreshold" = derniere maj des forets Windows (2016) avec ses features
#   -DatabasePath                 : NT Directory Services Database
#   -LogPath                      : log NTDS ; la synchro ecrit d'abord ici puis met a jour
#   -SysvolPath                   : dossier partage entre les DC (GPO, scripts de logon repliques)
#   -CreateDnsDelegation:$false   : ne cree pas de delegation DNS vers un sous-domaine
#   -InstallDns:$true             : installe le role DNS (traduit les noms AD en IP)
#   -NoRebootOnCompletion:$false  : le serveur redemarrera automatiquement a la fin
Install-ADDSForest `
    -DomainName $Domain `
    -DomainNetbiosName $Netbios `
    -SafeModeAdministratorPassword $DSRM `
    -ForestMode "WinThreshold" `
    -DomainMode "WinThreshold" `
    -DatabasePath "C:\Windows\NTDS" `
    -LogPath "C:\Windows\NTDS" `
    -SysvolPath "C:\Windows\SYSVOL" `
    -CreateDnsDelegation:$false `
    -InstallDns:$true `
    -NoRebootOnCompletion:$false `
    -Force:$true
