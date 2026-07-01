# ReadGroupInformation.ps1 - Recupere les informations d'un groupe AD
# Si aucune propriete specifiee, recupere tout
# Parametres : GroupName, PropertyName (optionnel)
. "$PSScriptRoot\helpers.ps1"
$Group = Get-Input "Nom du groupe" "Groupe" "IT"
Assert-GroupExists $Group
$Prop  = Get-OptionalInput "Propriete specifique (vide = tout)" "Propriete"
if ($Prop) { Get-ADGroup -Identity $Group -Properties $Prop | Select-Object $Prop | Format-List }
else       { Get-ADGroup -Identity $Group -Properties * | Format-List }
