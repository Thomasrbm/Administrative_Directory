# ListUserInGroup.ps1 - Liste tous les membres d'un groupe AD
# Parametres : GroupName
. "$PSScriptRoot\helpers.ps1"


$Group = Get-Input "Nom du groupe" "Groupe" "IT"
Assert-GroupExists $Group

$Members = Get-ADGroupMember -Identity $Group -Recursive

if ($Members.Count -eq 0) { Write-Host "Aucun membre dans '$Group'." -ForegroundColor Yellow }

else { $Members | Select-Object Name, SamAccountName, ObjectClass | Format-Table -AutoSize }
