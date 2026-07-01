# ModifyGroup.ps1 - Modifie un attribut d'un groupe AD
# Parametres : GroupName, AttributeName, NewValue


. "$PSScriptRoot\helpers.ps1"
Test-Admin


$Group = Get-Input "Nom du groupe" "Groupe" "IT"
Assert-GroupExists $Group
$Attr  = Get-Input "Attribut a modifier (ex: Description, DisplayName)" "Attribut" "Description"
$Value = Get-Input "Nouvelle valeur pour '$Attr'" "Valeur" "Groupe IT"

# --- AVANT : valeur de l'attribut avant la modification (preuve visuelle) ---
Write-Host "`n[AVANT] Valeur de l'attribut '$Attr' avant modification :" -ForegroundColor Cyan
Get-ADGroup -Identity $Group -Properties $Attr | Select-Object Name, $Attr | Format-List

Set-ADGroup -Identity $Group -Replace @{ $Attr = $Value }
Write-Host "Attribut '$Attr' du groupe '$Group' mis a jour." -ForegroundColor Green

# --- APRES : on relit l'attribut modifie pour prouver la nouvelle valeur ---
Write-Host "`n[APRES] Nouvelle valeur de l'attribut '$Attr' :" -ForegroundColor Cyan
Get-ADGroup -Identity $Group -Properties $Attr | Select-Object Name, $Attr | Format-List
