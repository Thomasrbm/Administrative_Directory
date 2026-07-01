# RemoveUserToGroup.ps1 - Retire un utilisateur d'un groupe AD
# Bloque si l'utilisateur est inconnu ou pas dans le groupe
# Parametres : UserName, GroupName

. "$PSScriptRoot\helpers.ps1"

Test-Admin


$User  = Get-Input "Nom du compte utilisateur a retirer" "Utilisateur" "admin.test"
Assert-UserExists $User

$Group = Get-Input "Nom du groupe" "Groupe" "IT"
Assert-GroupExists $Group


$Members = Get-ADGroupMember -Identity $Group | Select-Object -ExpandProperty SamAccountName
if ($Members -notcontains $User) { Write-Host "'$User' n'est pas dans le groupe '$Group'. Operation bloquee." -ForegroundColor Red; exit }

# --- AVANT : membres du groupe avant le retrait (preuve visuelle) ---
Write-Host "`n[AVANT] Membres de '$Group' avant le retrait :" -ForegroundColor Cyan
Get-ADGroupMember -Identity $Group | Select-Object Name, SamAccountName | Format-Table -AutoSize

Remove-ADGroupMember -Identity $Group -Members $User -Confirm:$false
Write-Host "'$User' retire du groupe '$Group'." -ForegroundColor Green

# --- APRES : '$User' a-t-il bien disparu de la liste des membres ? ---
Write-Host "`n[APRES] Presence de '$User' dans '$Group' :" -ForegroundColor Cyan
if (Get-ADGroupMember -Identity $Group | Where-Object SamAccountName -eq $User) {
    Write-Host "ECHEC : '$User' est toujours membre de '$Group'." -ForegroundColor Red
} else {
    Write-Host "OK : '$User' n'est plus dans '$Group'." -ForegroundColor Green
}
