# =============================================================
# tester.ps1
# Description : Test automatique de TOUTES les operations du sujet (hors main).
#               Reproduit les actions des scripts user/groupe/base avec des
#               valeurs de test fixes (pas de popup), affiche la preuve
#               [AVANT]/[APRES] de chaque operation, puis nettoie les objets
#               de test. A lancer sur un DC (SRV-ADMIN ou SRV-WORKSHOP : l'AD
#               est replique, le resultat est le meme).
#               PAUSE apres chaque test (Entree = test suivant) pour pouvoir
#               lire chaque resultat. Tout est aussi journalise dans
#               C:\test_resultats.txt pour relecture.
# =============================================================
. "$PSScriptRoot\helpers.ps1"
Test-Admin

# Journalise toute la sortie dans un fichier (relecture / preuve)
Start-Transcript -Path "C:\test_resultats.txt" -Force | Out-Null

# Pause entre chaque test pour laisser le temps de lire le resultat
function Pause-Test { Read-Host "`n--- [Entree] pour le test suivant ---" | Out-Null }

$OU   = "CN=Users,$((Get-ADDomain).DistinguishedName)"
$Dom  = (Get-ADDomain).DNSRoot
$Pass = ConvertTo-SecureString "Bonjour123**" -AsPlainText -Force

Write-Host "==== TEST AUTOMATIQUE DES SCRIPTS DU SUJET ====" -ForegroundColor Magenta

# Nettoyage prealable (silencieux : on verifie l'existence avant de supprimer,
# sinon le 1er lancement affiche des erreurs rouges "object not found" inutiles)
foreach ($g in "TestGroup", "TestGroup2", "TestDistri") {
    if (Get-ADGroup -Filter "Name -eq '$g'" -ErrorAction SilentlyContinue) { Remove-ADGroup $g -Confirm:$false }
}
if (Get-ADUser -Filter "SamAccountName -eq 'test.user'" -ErrorAction SilentlyContinue) { Remove-ADUser test.user -Confirm:$false }

# [1] UserCreation
Write-Host "`n[1] UserCreation -> test.user" -ForegroundColor Cyan
New-ADUser -SamAccountName test.user -Name "Test User" -GivenName Test -Surname User `
    -UserPrincipalName "test.user@$Dom" -AccountPassword $Pass -Enabled $true -Path $OU
Get-ADUser test.user | Select-Object SamAccountName, Enabled | Format-List
Pause-Test

# [2] ReadUserInformation
Write-Host "`n[2] ReadUserInformation" -ForegroundColor Cyan
Get-ADUser test.user -Properties * | Select-Object SamAccountName, Name, UserPrincipalName, Enabled | Format-List
Pause-Test

# [3] EditUserAttribute (Title)
Write-Host "`n[3] EditUserAttribute (Title)" -ForegroundColor Cyan
Write-Host "[AVANT] Title = $((Get-ADUser test.user -Properties Title).Title)"
Set-ADUser test.user -Replace @{ Title = "Ingenieur" }
Write-Host "[APRES] Title = $((Get-ADUser test.user -Properties Title).Title)"
Pause-Test

# [4] ResetUserPassword
Write-Host "`n[4] ResetUserPassword" -ForegroundColor Cyan
Set-ADAccountPassword test.user -Reset -NewPassword (ConvertTo-SecureString "Nouveau123**" -AsPlainText -Force)
Write-Host "OK : mot de passe reinitialise"
Pause-Test

# [5] CreateGroup
Write-Host "`n[5] CreateGroup -> TestGroup" -ForegroundColor Cyan
New-ADGroup -Name TestGroup -GroupScope Global -GroupCategory Security -Path $OU
Get-ADGroup TestGroup | Select-Object Name, GroupScope, GroupCategory | Format-List
Pause-Test

# [6] CreateDistributionGroup
Write-Host "`n[6] CreateDistributionGroup -> TestDistri" -ForegroundColor Cyan
New-ADGroup -Name TestDistri -GroupScope Universal -GroupCategory Distribution -Path $OU
Get-ADGroup TestDistri | Select-Object Name, GroupCategory | Format-List
Pause-Test

# [7] AddUserToGroup (test.user -> TestGroup)
Write-Host "`n[7] AddUserToGroup" -ForegroundColor Cyan
Write-Host "[AVANT] membres : $((Get-ADGroupMember TestGroup).SamAccountName -join ', ')"
Add-ADGroupMember TestGroup -Members test.user
Write-Host "[APRES] membres : $((Get-ADGroupMember TestGroup).SamAccountName -join ', ')"
Pause-Test

# [8] ListUserInGroup
Write-Host "`n[8] ListUserInGroup (TestGroup)" -ForegroundColor Cyan
Get-ADGroupMember TestGroup | Select-Object Name, SamAccountName | Format-Table -AutoSize
Pause-Test

# [9] ModifyGroup (Description)
Write-Host "`n[9] ModifyGroup (Description)" -ForegroundColor Cyan
Write-Host "[AVANT] Description = $((Get-ADGroup TestGroup -Properties Description).Description)"
Set-ADGroup TestGroup -Replace @{ Description = "Groupe de test" }
Write-Host "[APRES] Description = $((Get-ADGroup TestGroup -Properties Description).Description)"
Pause-Test

# [10] ImportGroup (TestGroup -> TestGroup2)
Write-Host "`n[10] ImportGroup (TestGroup -> TestGroup2)" -ForegroundColor Cyan
New-ADGroup -Name TestGroup2 -GroupScope Global -GroupCategory Security -Path $OU
Get-ADGroupMember TestGroup | ForEach-Object { Add-ADGroupMember TestGroup2 -Members $_.SamAccountName }
Write-Host "Membres de TestGroup2 : $((Get-ADGroupMember TestGroup2).SamAccountName -join ', ')"
Pause-Test

# [11] RemoveUserToGroup (test.user hors de TestGroup)
Write-Host "`n[11] RemoveUserToGroup" -ForegroundColor Cyan
Write-Host "[AVANT] membres : $((Get-ADGroupMember TestGroup).SamAccountName -join ', ')"
Remove-ADGroupMember TestGroup -Members test.user -Confirm:$false
Write-Host "[APRES] membres : $((Get-ADGroupMember TestGroup).SamAccountName -join ', ')"
Pause-Test

# [12] ReadGroupInformation
Write-Host "`n[12] ReadGroupInformation (TestGroup)" -ForegroundColor Cyan
Get-ADGroup TestGroup -Properties * | Select-Object Name, GroupScope, GroupCategory, Description | Format-List
Pause-Test

# [13] ReadEveryGroupInformation
Write-Host "`n[13] ReadEveryGroupInformation" -ForegroundColor Cyan
Get-ADGroup -Filter * | Select-Object Name, GroupCategory | Format-Table -AutoSize
Pause-Test

# [14] SaveDataBase + LoadDataBase
Write-Host "`n[14] SaveDataBase / LoadDataBase (CSV)" -ForegroundColor Cyan
Get-ADUser -Filter * -Properties SamAccountName, GivenName, Surname |
    Select-Object SamAccountName, GivenName, Surname |
    Export-Csv C:\test_db.csv -NoTypeInformation -Delimiter ";" -Encoding UTF8
$n = (Import-Csv C:\test_db.csv -Delimiter ";" | Measure-Object).Count
Write-Host "OK : $n users exportes puis relus depuis C:\test_db.csv"
Pause-Test

# [15] ReadDataBaseInformation
Write-Host "`n[15] ReadDataBaseInformation" -ForegroundColor Cyan
Get-ADUser -Filter * | Select-Object SamAccountName, Enabled | Format-Table -AutoSize
Pause-Test

# Nettoyage final des objets de test (silencieux, on verifie avant de supprimer)
Write-Host "`n==== NETTOYAGE ====" -ForegroundColor Magenta
foreach ($g in "TestGroup", "TestGroup2", "TestDistri") {
    if (Get-ADGroup -Filter "Name -eq '$g'" -ErrorAction SilentlyContinue) { Remove-ADGroup $g -Confirm:$false }
}
if (Get-ADUser -Filter "SamAccountName -eq 'test.user'" -ErrorAction SilentlyContinue) { Remove-ADUser test.user -Confirm:$false }
Remove-Item C:\test_db.csv -ErrorAction SilentlyContinue
Write-Host "Objets de test supprimes. TOUS LES TESTS EXECUTES." -ForegroundColor Green
Write-Host "Journal complet : C:\test_resultats.txt" -ForegroundColor Green

Stop-Transcript | Out-Null
