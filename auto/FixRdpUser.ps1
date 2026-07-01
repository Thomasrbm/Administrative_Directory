# =============================================================
# FixRdpUser.ps1
# Description : Prepare un utilisateur de domaine pour la connexion RDP
#               sur les DC, en une seule fois :
#                 1. (re)definit un mot de passe connu + enleve le
#                    changement force a la connexion (sinon le NLA bloque)
#                 2. accorde le droit "Ouvrir une session via Bureau a
#                    distance" sur les DC (Grant-DCLogon)
#                 3. applique la strategie (gpupdate, fait dans Grant-DCLogon)
#                    et VERIFIE que le droit est bien actif sur ce serveur
#               A lancer SUR LE DC ou l'on se connecte (ex: SRV-WORKSHOP).
# =============================================================
. "$PSScriptRoot\helpers.ps1"
Test-Admin

# Utilisateur cible (doit exister) + mot de passe a definir
$Login = Get-Input "Login a preparer pour le RDP (ex: user.admin)" "Login" "user.admin"
Assert-UserExists $Login
$Pass  = Get-Input "Mot de passe a definir" "Mot de passe" "Bonjour123**"

# 1. mot de passe connu + pas de changement force (debloque le NLA)
Set-ADAccountPassword -Identity $Login -Reset -NewPassword (ConvertTo-SecureString $Pass -AsPlainText -Force)
Set-ADUser -Identity $Login -ChangePasswordAtLogon $false

# 2. droit RDP sur les DC + gpupdate (factorise dans le helper)
Grant-DCLogon $Login

# 3. verification : le SID doit apparaitre dans le droit RDP effectif de CE serveur
$sid = (Get-ADUser $Login).SID.Value
secedit /export /cfg C:\c.cfg /quiet
$line = (Select-String "SeRemoteInteractiveLogonRight" C:\c.cfg).Line
# secedit affiche soit le SID, soit le nom de compte resolu -> on teste les deux
if ($line -match [regex]::Escape($sid) -or $line -match [regex]::Escape($Login)) {
    Write-Host "OK : $Login a le droit RDP actif sur ce DC. Connexion possible avec le mot de passe defini." -ForegroundColor Green
} else {
    Write-Host "ATTENTION : le droit RDP n'apparait pas encore actif sur ce DC (replication GPO en cours ?). Relance ce script dans 1 min." -ForegroundColor Yellow
}
