# CreateGroup.ps1 - Cree un nouveau groupe de securite AD
# Parametres : GroupName, OrganisationUnit, GroupScope, Description
. "$PSScriptRoot\helpers.ps1"
Test-Admin
$Name  = Get-Input "Nom du groupe" "Groupe" "IT"
$OU    = Get-Input "Organizational Unit (ex: CN=Users,DC=domolia,DC=local)" "OU" "CN=Users,DC=domolia,DC=local"
$Scope = Get-Input "Etendue (Global, Universal, DomainLocal)" "Scope" "Global"
$Desc  = Get-OptionalInput "Description du groupe" "Description"
New-ADGroup -Name $Name -GroupScope $Scope -GroupCategory Security -Path $OU -Description $Desc
Write-Host "Groupe '$Name' cree." -ForegroundColor Green

# --- VERIFICATION : on relit le groupe dans AD pour prouver qu'il existe ---
Write-Host "`n[VERIFICATION] Lecture du groupe cree :" -ForegroundColor Cyan
Get-ADGroup -Identity $Name -Properties Description |
    Select-Object Name, GroupScope, GroupCategory, Description, DistinguishedName | Format-List
