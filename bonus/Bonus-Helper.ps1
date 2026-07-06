# siem/Bonus-Helper.ps1

# 1. Chargement des librairies graphiques
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# 2. Fonction pour afficher des Pop-ups proprement
function Show-Popup {
    param (
        [string]$Message,
        [string]$Title = "SIEM Information",
        [int]$Icon = 64 # 64 = Info, 48 = Warning, 16 = Error
    )
    $wshell = New-Object -ComObject Wscript.Shell
    $wshell.Popup($Message, 0, $Title, $Icon) | Out-Null
}

# 3. Fonction pour exécuter Auditpol silencieusement
function Set-SiemAudit {
    param (
        [string]$Subcategory,
        [string]$State # "enable" ou "disable"
    )
    auditpol /set /subcategory:$Subcategory /success:$State /failure:$State | Out-Null
}

# 4. Fonction pour générer le menu graphique Windows
function Show-SiemCheckboxMenu {
    param (
        [string]$Title,
        [string]$LabelText,
        [string]$ButtonText
    )
    
    $form = New-Object System.Windows.Forms.Form
    $form.Text = $Title
    $form.Size = New-Object System.Drawing.Size(380,250)
    $form.StartPosition = "CenterScreen"

    $label = New-Object System.Windows.Forms.Label
    $label.Text = $LabelText
    $label.Location = New-Object System.Drawing.Point(20,15)
    $label.AutoSize = $true
    $form.Controls.Add($label)

    $cb1 = New-Object System.Windows.Forms.CheckBox
    $cb1.Text = "1. Accès aux Fichiers (File System)"
    $cb1.Location = New-Object System.Drawing.Point(20,45)
    $cb1.Size = New-Object System.Drawing.Size(300,20)
    $form.Controls.Add($cb1)

    $cb2 = New-Object System.Windows.Forms.CheckBox
    $cb2.Text = "2. Création de Processus (Process Creation)"
    $cb2.Location = New-Object System.Drawing.Point(20,75)
    $cb2.Size = New-Object System.Drawing.Size(300,20)
    $form.Controls.Add($cb2)

    $cb3 = New-Object System.Windows.Forms.CheckBox
    $cb3.Text = "3. Modification de Politique (Policy Change)"
    $cb3.Location = New-Object System.Drawing.Point(20,105)
    $cb3.Size = New-Object System.Drawing.Size(300,20)
    $form.Controls.Add($cb3)

    $btnOK = New-Object System.Windows.Forms.Button
    $btnOK.Text = $ButtonText
    $btnOK.Location = New-Object System.Drawing.Point(40,160)
    $btnOK.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.Controls.Add($btnOK)

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = "Annuler"
    $btnCancel.Location = New-Object System.Drawing.Point(140,160)
    $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.Controls.Add($btnCancel)

    $form.AcceptButton = $btnOK
    $form.CancelButton = $btnCancel

    $result = $form.ShowDialog()

    # Si l'utilisateur clique sur OK, on renvoie l'état des cases
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        return [pscustomobject]@{
            FileSys = $cb1.Checked
            Process = $cb2.Checked
            Policy  = $cb3.Checked
        }
    }
    return $null
}