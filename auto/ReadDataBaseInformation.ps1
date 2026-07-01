# ReadDataBaseInformation.ps1 - Recupere les informations de tous les utilisateurs AD
# Parametres : Filter (optionnel)


. "$PSScriptRoot\helpers.ps1"

$Filter = Get-OptionalInput "Attributs a recuperer separes par virgules (vide = tout)" "Filtre"

if ($Filter) {
    $Props = Get-PropsList $Filter
    Get-ADUser -Filter * -Properties $Props | Select-Object $Props | Format-Table -AutoSize
} else {
    Get-ADUser -Filter * -Properties * | Format-List
}
