# EditUserAttribute.ps1 - Modifie un attribut d'un utilisateur AD
# Parametres : AccountName, AttributeName, DesiredValue
. "$PSScriptRoot\helpers.ps1"
Test-Admin
$User  = Get-Input "Nom du compte utilisateur" "Compte" "admin.test"
Assert-UserExists $User
$Attr  = Get-Input "Attribut a modifier (ex: Title, Department)" "Attribut" "Title"
$Value = Get-Input "Nouvelle valeur pour '$Attr'" "Valeur" "Administrateur"

# --- AVANT : valeur de l'attribut avant la modification (preuve visuelle) ---
Write-Host "`n[AVANT] Valeur de '$Attr' avant modification :" -ForegroundColor Cyan
Get-ADUser -Identity $User -Properties $Attr | Select-Object SamAccountName, $Attr | Format-List

Set-ADUser -Identity $User -Replace @{ $Attr = $Value }
Write-Host "Attribut '$Attr' de $User mis a jour avec '$Value'." -ForegroundColor Green

# --- APRES : on relit l'attribut sur le compte pour prouver la nouvelle valeur ---
Write-Host "`n[APRES] Valeur de '$Attr' apres modification :" -ForegroundColor Cyan
Get-ADUser -Identity $User -Properties $Attr | Select-Object SamAccountName, $Attr | Format-List
