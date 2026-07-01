# ReadEveryGroupInformation.ps1 - Recupere les informations de tous les groupes AD
# Si aucune propriete specifiee, recupere tout
# Parametres : PropertyName (optionnel)
. "$PSScriptRoot\helpers.ps1"
$Prop = Get-OptionalInput "Propriete specifique (vide = tout)" "Propriete"
if ($Prop) { Get-ADGroup -Filter * -Properties $Prop | Select-Object Name, $Prop | Format-Table -AutoSize }
else       { Get-ADGroup -Filter * -Properties * | Format-List }
