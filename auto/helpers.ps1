# =============================================================
# helpers.ps1
# Description : Fonctions utilitaires communes a tous les scripts AD
#               A inclure avec : . "$PSScriptRoot\helpers.ps1"
# =============================================================

# Chargement des assembly pour les popups
Add-Type -AssemblyName Microsoft.VisualBasic   # InputBox (saisie texte)
Add-Type -AssemblyName System.Windows.Forms    # fenetre pour le pop-up mot de passe masque
Add-Type -AssemblyName System.Drawing          # taille/position des controles

# Verifie que le script est lance en tant qu'administrateur
function Test-Admin {
    # [] un type ,  Securiy.  ...  chemin vers la classe,  :: methode
    # getcurrent => renvoit obj windowidentity (compte, nom groupe)  
    # IsInRole  = methode de WindowsPrincipal  => verif si admin
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "Droits administrateur requis." -ForegroundColor Red
        exit
    }
}

# Affiche un popup et retourne la valeur saisie (obligatoire)
# 3 param dont default non obligatoire et vaut "" par defaut
function Get-Input($message, $title, $default = "") {
    # result stock,  input ouvre boite , message = question, title = titre window, default = si champs par defaut
    $result = [Microsoft.VisualBasic.Interaction]::InputBox($message, $title, $default)
    if ([string]::IsNullOrWhiteSpace($result)) {
        Write-Host "Champ '$title' requis. Abandon." -ForegroundColor Red
        exit
    }
    return $result
}

# Affiche un popup et retourne la valeur saisie (optionnelle)
# peut etre vide, pas de if vide
function Get-OptionalInput($message, $title, $default = "") {
    return [Microsoft.VisualBasic.Interaction]::InputBox($message, $title, $default)
}

# Affiche un POP-UP avec un champ MASQUE et retourne le mot de passe en SecureString.
# Respecte la regle "demander toute information via un pop-up" sans afficher le mdp en clair
# (contrairement a InputBox). Construit une petite fenetre Windows Forms.
function Get-PasswordInput($message, $title) {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = $title
    $form.Size = New-Object System.Drawing.Size(380, 170)
    $form.StartPosition = "CenterScreen"
    $form.TopMost = $true   # passe au premier plan

    # Libelle : la question posee
    $label = New-Object System.Windows.Forms.Label
    $label.Text = $message
    $label.AutoSize = $true
    $label.Location = New-Object System.Drawing.Point(12, 15)
    $form.Controls.Add($label)

    # Champ de saisie masque (les caracteres sont remplaces par des points)
    $box = New-Object System.Windows.Forms.TextBox
    $box.UseSystemPasswordChar = $true
    $box.Location = New-Object System.Drawing.Point(12, 45)
    $box.Size = New-Object System.Drawing.Size(345, 25)
    $form.Controls.Add($box)

    # Bouton OK (+ touche Entree valide la fenetre)
    $ok = New-Object System.Windows.Forms.Button
    $ok.Text = "OK"
    $ok.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $ok.Location = New-Object System.Drawing.Point(280, 85)
    $form.Controls.Add($ok)
    $form.AcceptButton = $ok

    # Affichage : si annule ou vide -> on bloque (champ requis)
    if ($form.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK -or [string]::IsNullOrEmpty($box.Text)) {
        Write-Host "Mot de passe '$title' requis. Abandon." -ForegroundColor Red
        exit
    }
    # Conversion en SecureString (le mdp n'est jamais conserve en clair au-dela de cette ligne)
    return (ConvertTo-SecureString $box.Text -AsPlainText -Force)
}

# Verifie qu'un utilisateur AD existe, quitte sinon
function Assert-UserExists($username) {
    # cherche user dans ad
    # -filter critere de recherceh comme Where en sql
    # Sam = nom de connexion
    # -eq egale a 
    # ne pas planter en cas d etteur 
    if (-not (Get-ADUser -Filter { SamAccountName -eq $username } -ErrorAction SilentlyContinue)) {
        Write-Host "Utilisateur '$username' introuvable. Operation bloquee." -ForegroundColor Red
        exit
    }
}



# Verifie qu'un groupe AD existe, quitte sinon
function Assert-GroupExists($groupname) {
    if (-not (Get-ADGroup -Filter { Name -eq $groupname } -ErrorAction SilentlyContinue)) {
        Write-Host "Groupe '$groupname' introuvable. Operation bloquee." -ForegroundColor Red
        exit
    }
}

# Cree un dossier, le partage en SMB et accorde les droits NTFS "Modify" a un compte

# path ou on cree : C:\AdminFiles par ex
# nom du dossier : AdminFiles ex
# account avec droit : admin ex
function New-WorkFolder($path, $shareName, $account) {
    # cree,  type  directory,  le fonction renvoit du text => out null l ignore, force ne plante pas si existe deja 
    New-Item -ItemType Directory -Path $path -Force | Out-Null
    # New-SmbShare = partage reseau,  fullacces pour le compte 
    # dans page shared
    New-SmbShare -Name $shareName -Path $path -FullAccess $account -ErrorAction SilentlyContinue | Out-Null
    # ACL = Access Control List = la liste des permissions d'un dossier ,    get = lit les permistion 
    # sera modif et reappliquer
    $acl  = Get-Acl $path
    # dams page security (double verrou)
    # nouvel obj, class access rule de security
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
      $account,                          # QUI    → DOMOLIA\admin
      "Modify",                          # QUOI   → droit de modifier
      "ContainerInherit,ObjectInherit",  # OÙ     → + sous-dossiers + fichiers
      "None",                            # (propagation) → rien de spécial
      "Allow")                           # SENS   → autoriser (pas interdire)
    # applique modif sur la version ram en memoire (run time)
    $acl.SetAccessRule($rule)
    # applique sur le disque
    Set-Acl $path $acl
    Write-Host "Dossier '$path' cree, partage ($shareName) et droits Modify accordes a $account." -ForegroundColor Green
}

# Ajoute un compte aux permissions d'un dossier partage DEJA existant
# (acces SMB + droits NTFS Modify). Sert a donner acces a un dossier commun
# (ex: GenericFiles) a un utilisateur supplementaire, sans le recreer.
function Grant-FolderAccess($path, $shareName, $account) {
    # acces au partage SMB existant : Grant-SmbShareAccess (et non New-SmbShare)
    Grant-SmbShareAccess -Name $shareName -AccountName $account -AccessRight Full -Force | Out-Null
    # droits NTFS Modify (+ sous-dossiers + fichiers), comme dans New-WorkFolder
    $acl  = Get-Acl $path
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
      $account, "Modify", "ContainerInherit,ObjectInherit", "None", "Allow")
    $acl.SetAccessRule($rule)
    Set-Acl $path $acl
    Write-Host "$account ajoute aux permissions de $shareName ($path)." -ForegroundColor Green
}

# Autorise un utilisateur de domaine NON-admin a ouvrir une session sur les DC
function Grant-DCLogon($username) {
    Assert-UserExists $username
    # Ajoute l'utilisateur au groupe "Remote Desktop Users".
    Add-ADGroupMember -Identity "Remote Desktop Users" -Members $username -ErrorAction SilentlyContinue
    # SID (Security Identifier) *<SID>   
    $Sid  = "*" + (Get-ADUser $username).SID.Value
    # Default Domain Controllers Policy : son GUID est fixe et identique partout
    $Dom  = (Get-ADDomain).DNSRoot  # Recup domaine courrant
    $Guid = "{6AC1786C-016F-11D2-945F-00C04fB984F9}" # id de la GPO "Default Domain Controllers Policy"  => permet de cibler les GPO de droit des DC
    $Inf  = "\\$Dom\SYSVOL\$Dom\Policies\$Guid\MACHINE\Microsoft\Windows NT\SecEdit\GptTmpl.inf" # chemin du fichier des droit user applique aux DC
    # save de safety avant modif
    Copy-Item $Inf "$Inf.bak" -Force
    # droit  de connexion sur une DC 
    $Rights = @{
        "SeInteractiveLogonRight"       = "*S-1-5-32-544"  # = droit physique sur le pc
        "SeRemoteInteractiveLogonRight" = "*S-1-5-32-544" # = droit remote desktop
    }
    $Lines = Get-Content $Inf
    # itere sur chaque droit dans les 2 lignes de rights, sur chaque ligne
    foreach ($Right in $Rights.Keys) {
        # contient ^Right au debut, \s* (plusieurs space tab ou pas apres, =)   = chope le num de ligne
        $Idx = ($Lines | Select-String "^$Right\s*=").LineNumber
        if ($Idx) {
            # la ligne existe : on ajoute notre SID s'il n'y est pas deja
            $i = $Idx - 1 # converti en idx tableua (commence a 0)

            # ajoute le SID current a la ligne found sinon le lecteur interpretera les* en repetition,  le - en "plage" => esapce separe tout par des \ et donc 
            # li litterallement
            if ($Lines[$i] -notmatch [regex]::Escape($Sid)) {
                $Lines[$i] = $Lines[$i].TrimEnd() + ",$Sid"
            }
        } else {
            # la ligne n'existe pas : on la cree (Administrateurs + notre user)
            $Sec   = ($Lines | Select-String "^\[Privilege Rights\]").LineNumber # trouve la ligne des droits
            $New   = "$Right = $($Rights[$Right]),$Sid" # ajoute les 2 lignes
            # garde les lignes avant $Lines[0..($Sec-1)]   puis nos lgines puis les lignes apres , Count-1(pour tab)
            $Lines = $Lines[0..($Sec-1)] + $New + $Lines[$Sec..($Lines.Count-1)]
        }
    }
    # GptTmpl.inf doit etre enregister en UTF 16 sinon corrompu.
    Set-Content $Inf $Lines -Encoding Unicode
    # fichier de metadonne de la GPO (car si pas de modif de version, pas de reinterpretation)
    $Gpt  = "\\$Dom\SYSVOL\$Dom\Policies\$Guid\GPT.ini"
    # choppe la ligne version
    $Line = Get-Content $Gpt | Where-Object { $_ -match '^Version=' } | Select-Object -First 1
    # garde enleve tout char non numerique
    $Ver  = [int]($Line -replace '\D', '')
    # remplace par donc la lgine par la version du dessus
    (Get-Content $Gpt) -replace "Version=\d+", "Version=$($Ver + 1)" | Set-Content $Gpt
    # exec
    gpupdate /force | Out-Null
    Write-Host "Droits de connexion (locale + RDP) accordes a $username sur les controleurs de domaine." -ForegroundColor Green
}

# affichage : transforme une saisie "a, b, c" en tableau de proprietes nettoyees (sans espaces)
function Get-PropsList($csv) {
    return $csv -split "," | ForEach-Object { $_.Trim() }
}
