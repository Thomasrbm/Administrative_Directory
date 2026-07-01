# =============================================================
# main_admin_post.ps1
# Description : Script principal POST-REBOOT pour le SERVEUR ADMINISTRATEUR
#               A lancer apres le redemarrage suivant la creation de la foret
#               1. Cree le compte administrateur
#               2. Cree les dossiers partages (admin + generique)
#               3. Configure les permissions NTFS et SMB pour l'utilisateur cree
# =============================================================

# recup les ft
$ScriptDir = "$PSScriptRoot"
. "$ScriptDir\helpers.ps1"
Test-Admin

Write-Host "Reponds aux fenetres popup au fur et a mesure (Alt+Tab si elles sont cachees)." -ForegroundColor Cyan

# Etape 1 : Configuration des forwarders DNS (resolution des noms externes -> internet)
# Le DC est serveur DNS pour tout le domaine. Sans forwarder il ne resout pas
# les noms publics (google.com...), ce qui donne l'impression de "plus d'internet".
$Forwarder = Get-Input "DNS forwarder externe (DNS de l'ecole ou public, ex: 8.8.8.8)" "DNS Forwarder" "8.8.8.8"
Add-DnsServerForwarder -IPAddress $Forwarder -ErrorAction SilentlyContinue

#  = si un pc demande un dns que tu connais pas, renvoit vers google





# Etape 2 : Creation du compte administrateur
& "$ScriptDir\UserCreation.ps1"

# Recuperation du login cree (prenom.nom) et du domaine
$UserLogin = Get-Input "Entrez le login du compte venant d'etre cree (ex: user.admin)" "Login cree" "user.admin"
$Account   = "$((Get-ADDomain).NetBIOSName)\$UserLogin"

# Etape 3 : Autorise ce user non-admin a ouvrir une session sur les DC (locale + RDP)
Grant-DCLogon $UserLogin

# Etape 4 : Leve "changer le mdp au 1er logon" (mis par UserCreation, exigence sujet)
# pour que ce compte puisse se connecter direct en RDP (le NLA bloque sinon).
Set-ADUser -Identity $UserLogin -ChangePasswordAtLogon $false

# Etape 5 & 6 : Dossiers partages + permissions SMB/NTFS (via le helper New-WorkFolder)
$AdminFolder   = Get-Input "Chemin du dossier administratif" "Dossier admin" "C:\AdminFiles"
$GenericFolder = Get-Input "Chemin du dossier generique" "Dossier generique" "C:\GenericFiles"
New-WorkFolder $AdminFolder   "AdminFiles"   $Account
New-WorkFolder $GenericFolder "GenericFiles" $Account
