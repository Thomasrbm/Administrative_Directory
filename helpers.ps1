# =============================================================
# helpers.ps1  (Administrative_Directory)
# Description : Fonctions utilitaires communes aux scripts GPO / permissions / SIEM.
#               Reprend les popups/Test-Admin d'Automatic_Directory et ajoute
#               les helpers NTFS (ACL/SACL) propres a ce sujet.
#               A inclure avec : . "$PSScriptRoot\helpers.ps1"  (adapter le chemin)
# =============================================================

# Assembly pour les popups (saisie texte + mot de passe masque)
Add-Type -AssemblyName Microsoft.VisualBasic
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- Verifie que le script tourne en administrateur ---
function Test-Admin {
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "Droits administrateur requis." -ForegroundColor Red
        exit
    }
}

# --- Popup de saisie obligatoire ---
function Get-Input($message, $title, $default = "") {
    $result = [Microsoft.VisualBasic.Interaction]::InputBox($message, $title, $default)
    if ([string]::IsNullOrWhiteSpace($result)) {
        Write-Host "Champ '$title' requis. Abandon." -ForegroundColor Red
        exit
    }
    return $result
}

# --- Popup de saisie optionnelle (peut etre vide) ---
function Get-OptionalInput($message, $title, $default = "") {
    return [Microsoft.VisualBasic.Interaction]::InputBox($message, $title, $default)
}

# --- Popup mot de passe masque -> SecureString ---
function Get-PasswordInput($message, $title) {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = $title
    $form.Size = New-Object System.Drawing.Size(380, 170)
    $form.StartPosition = "CenterScreen"
    $form.TopMost = $true
    $label = New-Object System.Windows.Forms.Label
    $label.Text = $message; $label.AutoSize = $true
    $label.Location = New-Object System.Drawing.Point(12, 15)
    $form.Controls.Add($label)
    $box = New-Object System.Windows.Forms.TextBox
    $box.UseSystemPasswordChar = $true
    $box.Location = New-Object System.Drawing.Point(12, 45)
    $box.Size = New-Object System.Drawing.Size(345, 25)
    $form.Controls.Add($box)
    $ok = New-Object System.Windows.Forms.Button
    $ok.Text = "OK"; $ok.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $ok.Location = New-Object System.Drawing.Point(280, 85)
    $form.Controls.Add($ok); $form.AcceptButton = $ok
    if ($form.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK -or [string]::IsNullOrEmpty($box.Text)) {
        Write-Host "Mot de passe '$title' requis. Abandon." -ForegroundColor Red
        exit
    }
    return (ConvertTo-SecureString $box.Text -AsPlainText -Force)
}

# --- Verifie qu'un groupe AD existe ---
function Assert-GroupExists($groupname) {
    if (-not (Get-ADGroup -Filter { Name -eq $groupname } -ErrorAction SilentlyContinue)) {
        Write-Host "Groupe '$groupname' introuvable. Operation bloquee." -ForegroundColor Red
        exit
    }
}

# =============================================================
# HELPERS NTFS (permissions dossiers)
# =============================================================

# Convertit un niveau logique de la matrice en droits NTFS reels.
# On renvoie un [System.Security.AccessControl.FileSystemRights].
function ConvertTo-FileSystemRights($level) {
    switch ($level) {
        # lecture + liste + execution
        "Read"          { return [System.Security.AccessControl.FileSystemRights]"ReadAndExecute" }
        # lecture + creation/ecriture MAIS pas de suppression (Write n'inclut pas Delete)
        "WriteNoDelete" { return [System.Security.AccessControl.FileSystemRights]"ReadAndExecute, Write" }
        # droit complet : lecture + ecriture + creation + suppression
        "Modify"        { return [System.Security.AccessControl.FileSystemRights]"Modify" }
        default {
            Write-Host "Niveau de permission inconnu : '$level'." -ForegroundColor Red
            exit
        }
    }
}

# Repart d'une ACL propre : on coupe l'heritage (protection) et on ne garde
# qu'une base sure (SYSTEM + Administrateurs en Full) pour ne pas se verrouiller.
# Ensuite chaque groupe recevra EXACTEMENT le droit voulu par la matrice.
function Reset-FolderAcl($path) {
    $acl = Get-Acl $path
    # $true = proteger de l'heritage, $false = ne pas recopier les regles heritees
    $acl.SetAccessRuleProtection($true, $false)
    # on enleve toutes les regles residuelles
    $acl.Access | ForEach-Object { [void]$acl.RemoveAccessRule($_) }
    # base minimale pour rester administrable
    foreach ($who in @("NT AUTHORITY\SYSTEM", "BUILTIN\Administrators")) {
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $who, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
        $acl.AddAccessRule($rule)
    }
    Set-Acl $path $acl
}

# Accorde a un compte/groupe un droit NTFS sur un dossier (+ sous-dossiers + fichiers).
function Grant-NtfsRight($path, $identity, $level) {
    $rights = ConvertTo-FileSystemRights $level
    $acl  = Get-Acl $path
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        $identity, $rights, "ContainerInherit,ObjectInherit", "None", "Allow")
    $acl.SetAccessRule($rule)   # remplace si une regle Allow existe deja pour ce compte
    Set-Acl $path $acl
    Write-Host "  [$identity] -> $level ($rights) sur $path" -ForegroundColor Green
}

# Partage SMB d'un dossier si pas deja partage (necessaire pour l'acces reseau).
function Publish-Share($path, $shareName) {
    if (-not (Get-SmbShare -Name $shareName -ErrorAction SilentlyContinue)) {
        # -FullAccess "Authenticated Users" : le filtrage fin se fait au niveau NTFS (double verrou).
        New-SmbShare -Name $shareName -Path $path -FullAccess "Authenticated Users" | Out-Null
        Write-Host "Partage SMB '$shareName' cree pour $path." -ForegroundColor Green
    }
}

# =============================================================
# HELPER SACL (audit d'acces dossier -> genere les EventID 4663)
# =============================================================
# Activer la categorie "File System" ne suffit PAS : il faut poser une regle
# d'AUDIT (SACL) sur le dossier lui-meme, sinon aucun 4663 ne remonte.
function Enable-FolderAuditing($path) {
    $acl = Get-Acl $path -Audit
    # Audit des acces "Everyone" : reussite ET echec, sur dossier + sous-elements.
    $auditRule = New-Object System.Security.AccessControl.FileSystemAuditRule(
        "Everyone",
        "ReadAndExecute, Write, Delete, DeleteSubdirectoriesAndFiles",
        "ContainerInherit,ObjectInherit",
        "None",
        "Success,Failure")
    $acl.AddAuditRule($auditRule)
    Set-Acl $path $acl
    Write-Host "Audit (SACL) active sur $path -> les EventID 4663 seront generes." -ForegroundColor Green
}

# =============================================================
# HELPER GPO "script de logon" (deploiement de logiciels)
# =============================================================
# Windows n'a pas de cmdlet simple pour "assigner un MSI" via GPO. L'approche
# scriptable et fiable est une GPO qui execute un script PowerShell A LA
# CONNEXION de chaque utilisateur (User Configuration > Scripts > Logon).
# On ecrit le script dans SYSVOL, on renseigne psscripts.ini, on enregistre
# l'extension cliente "Scripts" et on incremente la version.
function New-LogonScriptGpo($gpoName, $scriptName, $scriptBody, $targetOUs) {
    Import-Module GroupPolicy    -ErrorAction Stop
    Import-Module ActiveDirectory -ErrorAction Stop

    $gpo = Get-GPO -Name $gpoName -ErrorAction SilentlyContinue
    if (-not $gpo) { $gpo = New-GPO -Name $gpoName; Write-Host "GPO '$gpoName' creee." -ForegroundColor Green }
    $guid = "{$($gpo.Id)}"
    $dom  = (Get-ADDomain).DNSRoot
    $base = "\\$dom\SYSVOL\$dom\Policies\$guid\User\Scripts"

    # 1) Ecrit le script de logon dans SYSVOL (replique sur tous les DC)
    New-Item -ItemType Directory -Path "$base\Logon" -Force | Out-Null
    Set-Content -Path "$base\Logon\$scriptName" -Value $scriptBody -Encoding UTF8

    # 2) psscripts.ini : declare le script PowerShell de logon (index 0)
    $ini = "[Logon]`r`n0CmdLine=$scriptName`r`n0Parameters="
    Set-Content -Path "$base\psscripts.ini" -Value $ini -Encoding Unicode

    # 3) Enregistre l'extension cliente "Scripts" (CSE) sur l'objet GPO
    #    CSE Scripts = {42B5FAAE-...}, outil = {40B6664F-...}
    $cse = "[{42B5FAAE-6536-11d2-AE5A-0000F87571E3}{40B6664F-4972-11d1-A7CA-0000F87571E3}]"
    Set-ADObject -Identity $gpo.Path -Replace @{ gPCUserExtensionNames = $cse }

    # 4) Incremente la version User (16 bits de poids fort) : AD + GPT.ini
    $obj = Get-ADObject -Identity $gpo.Path -Properties versionNumber
    $ver = [int]$obj.versionNumber
    $new = ((($ver -shr 16) + 1) -shl 16) -bor ($ver -band 0xFFFF)
    Set-ADObject -Identity $gpo.Path -Replace @{ versionNumber = $new }
    $gptIni = "\\$dom\SYSVOL\$dom\Policies\$guid\GPT.ini"
    (Get-Content $gptIni) -replace 'Version=\d+', "Version=$new" | Set-Content $gptIni

    # 5) Lie la GPO aux OU cibles
    foreach ($ou in $targetOUs) {
        New-GPLink -Name $gpoName -Target $ou -LinkEnabled Yes -ErrorAction SilentlyContinue | Out-Null
        Write-Host "GPO '$gpoName' liee a $ou" -ForegroundColor Green
    }
    Write-Host "Script de logon '$scriptName' deploye (version GPO -> $new)." -ForegroundColor Green
}
