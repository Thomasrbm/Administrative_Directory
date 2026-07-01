# UserCreation.ps1 - Cree un utilisateur AD
# Parametres : AccountName, OrganisationUnit, DesiredGroup
# Email : prenom.nom@domaine.com | UPN : email | MDP par defaut non stocke en clair


. "$PSScriptRoot\helpers.ps1"
Test-Admin


$First  = Get-Input "Prenom" "Prenom" "User"
$Last   = Get-Input "Nom de famille (Admin sur le serveur admin, Worker sur le worker)" "Nom" "Admin"
$OU     = Get-Input "Organizational Unit (ex: CN=Users,DC=domolia,DC=local)" "OU" "CN=Users,DC=domolia,DC=local"
$Group  = Get-OptionalInput "Groupe a rejoindre (optionnel)" "Groupe"
$Login  = "$($First.ToLower()).$($Last.ToLower())" #  me tout en min  . entre les 2
$Domain = "domolia.local" #  get le nom du dns (domolia.local)
$Email  = "$Login@$Domain"


# Mot de passe par defaut encode (TotalyN0tSecure) - non stocke en clair
# TotalyN0tSecure = mpd toujrous par defaut
# decode le mdp avec le base 64
# decode depuis unicode reonstuit la string
# asplain = texte en clair stocked
$Pass   = ConvertTo-SecureString ([System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String("VABvAHQAYQBsAHkATgAwAHQAUwBlAGMAdQByAGUA"))) -AsPlainText -Force



# hashtable

# Splatting : parametres regroupes dans un hashtable pour la lisibilite
# stock tous les prams 
$UserParams = @{
    SamAccountName        = $Login
    GivenName             = $First
    Surname               = $Last
    Name                  = "$First $Last"
    DisplayName           = "$First $Last"
    EmailAddress          = $Email
    UserPrincipalName     = $Email
    AccountPassword       = $Pass
    ChangePasswordAtLogon = $true
    Enabled               = $true
    Path                  = $OU
}

# cree user
New-ADUser @UserParams


Write-Host "Utilisateur $Login cree." -ForegroundColor Green

# ne secexutera pas car pas de groupe saisi
if ($Group) { Add-ADGroupMember -Identity $Group -Members $Login; Write-Host "Ajoute au groupe $Group." -ForegroundColor Green }

# --- VERIFICATION : on relit le compte dans AD pour prouver qu'il existe ---
Write-Host "`n[VERIFICATION] Lecture du compte cree :" -ForegroundColor Cyan
Get-ADUser -Identity $Login -Properties EmailAddress, Enabled |
    Select-Object SamAccountName, Name, EmailAddress, Enabled | Format-List
