# Chargement des outils graphiques pour les cases a cocher
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Creation de la fenetre principale
$form = New-Object System.Windows.Forms.Form
$form.Text = "Verification du SIEM"
$form.Size = New-Object System.Drawing.Size(350,200)
$form.StartPosition = "CenterScreen"

$label = New-Object System.Windows.Forms.Label
$label.Text = "Que voulez-vous verifier dans le terminal ?"
$label.Location = New-Object System.Drawing.Point(20,15)
$label.AutoSize = $true
$form.Controls.Add($label)

# Case 1 : Check logs
$cb1 = New-Object System.Windows.Forms.CheckBox
$cb1.Text = "1. Statut des logs (Active / Desactive)"
$cb1.Location = New-Object System.Drawing.Point(20,45)
$cb1.Size = New-Object System.Drawing.Size(300,20)
$form.Controls.Add($cb1)

# Case 2 : Check automate
$cb2 = New-Object System.Windows.Forms.CheckBox
$cb2.Text = "2. Statut de l'automatisation (Alertes)"
$cb2.Location = New-Object System.Drawing.Point(20,75)
$cb2.Size = New-Object System.Drawing.Size(300,20)
$form.Controls.Add($cb2)

$btnOK = New-Object System.Windows.Forms.Button
$btnOK.Text = "Verifier"
$btnOK.Location = New-Object System.Drawing.Point(40,120)
$btnOK.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.Controls.Add($btnOK)

$btnCancel = New-Object System.Windows.Forms.Button
$btnCancel.Text = "Annuler"
$btnCancel.Location = New-Object System.Drawing.Point(140,120)
$btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.Controls.Add($btnCancel)

$form.AcceptButton = $btnOK
$form.CancelButton = $btnCancel

# Affichage de la fenetre
$result = $form.ShowDialog()

# Actions si on clique sur Verifier
if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
    Clear-Host
    Write-Host "=== RESULTATS DE LA VERIFICATION SIEM ===" -ForegroundColor Cyan
    
    # 1. Verification des logs via auditpol
    if ($cb1.Checked) {
        Write-Host "`n[1] STATUT DES AUDITS (GPOs Bonus) :" -ForegroundColor Yellow
        $audits = @("File System", "Process Creation", "Audit Policy Change")
        foreach ($audit in $audits) {
            # On recupere le statut direct depuis Windows
            $status = (auditpol /get /subcategory:"$audit" | Select-String -Pattern "$audit").Line
            if ($status) {
                Write-Host " > $status" -ForegroundColor White
            } else {
                Write-Host " > $audit : Introuvable ou non configure" -ForegroundColor Red
            }
        }
    }
    
    # 2. Verification de l'automatisation
    if ($cb2.Checked) {
        Write-Host "`n[2] STATUT DE L'AUTOMATISATION :" -ForegroundColor Yellow
        $Rapport = "$home\Desktop\ALERTE_SIEM.txt"
        
        if (Test-Path $Rapport) {
            Write-Host "[OK] Fichier d'alerte trouve sur le bureau !" -ForegroundColor Green
            Write-Host "Contenu du rapport :" -ForegroundColor Gray
            Get-Content $Rapport | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
        } else {
            Write-Host "[INFO] Aucun fichier d'alerte trouve sur le bureau." -ForegroundColor Magenta
        }
        
        Write-Host "`nRecherche d'evenements critiques (5 dernieres minutes)..." -ForegroundColor Gray
        $Events = Get-WinEvent -FilterHashtable @{LogName='Security'; Id=@(4663, 4688, 4719, 4625); StartTime=(Get-Date).AddMinutes(-5)} -ErrorAction SilentlyContinue
        
        if ($Events) {
            Write-Host "[OK] $($Events.Count) evenement(s) critique(s) trouve(s) dans le journal." -ForegroundColor Green
        } else {
            Write-Host "[INFO] Aucun evenement critique recent a signaler." -ForegroundColor Magenta
        }
    }
    
    Write-Host "`n=== FIN DE LA VERIFICATION ===" -ForegroundColor Cyan
    Write-Host ""
}