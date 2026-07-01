# =============================================================
# AddUserToGenericFiles.ps1
# Description : Ajoute un utilisateur de domaine aux permissions du dossier
#               partage generique (acces SMB + droits NTFS Modify).
#               Le dossier GenericFiles est sur SRV-ADMIN : ce script se
#               lance donc SUR SRV-ADMIN. Logique dans Grant-FolderAccess.
# =============================================================
. "$PSScriptRoot\helpers.ps1"
Test-Admin

# Login a autoriser (doit deja exister dans l'AD)
$Login = Get-Input "Login a autoriser sur GenericFiles (ex: user.worker)" "Login" "user.worker"
Assert-UserExists $Login
$Account = "$((Get-ADDomain).NetBIOSName)\$Login"

# Dossier + partage (valeurs par defaut alignees sur main_admin_post.ps1)
$Path  = Get-Input "Chemin du dossier generique" "Dossier generique" "C:\GenericFiles"
$Share = Get-Input "Nom du partage SMB" "Partage" "GenericFiles"

Grant-FolderAccess $Path $Share $Account
