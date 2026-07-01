# =============================================================
# 05_CreateTestUsers.ps1 - Cree des utilisateurs de TEST (demo GPO + permissions)
#   1 user par groupe, place dans la bonne OU et ajoute a son groupe.
#   worker1 est aussi ajoute a OpenOfficeUsers pour prouver le deploiement
#   "a la demande" d'OpenOffice.
#   Idempotent : ne recree pas un user deja present.
# A lancer apres 02_CreateGroups.ps1 (les groupes doivent exister).
# =============================================================
. "$PSScriptRoot\..\helpers.ps1"
. "$PSScriptRoot\..\config.ps1"
Test-Admin
Import-Module ActiveDirectory -ErrorAction Stop

$sec = ConvertTo-SecureString $TestUserPassword -AsPlainText -Force

foreach ($u in $TestUsers) {

    # 1) Creer l'utilisateur (si absent)
    if (Get-ADUser -Filter "SamAccountName -eq '$($u.Name)'" -ErrorAction SilentlyContinue) {
        # Deja present : on reapplique mot de passe + options (idempotent)
        Set-ADAccountPassword -Identity $u.Name -Reset -NewPassword $sec
        Set-ADUser -Identity $u.Name -ChangePasswordAtLogon $false -PasswordNeverExpires $true -Enabled $true
        Write-Host "User '$($u.Name)' existe deja - mot de passe reinitialise." -ForegroundColor Yellow
    } else {
        New-ADUser -Name $u.Name -SamAccountName $u.Name `
            -UserPrincipalName "$($u.Name)@$Domain" `
            -DisplayName $u.Name -Path $u.OU `
            -AccountPassword $sec -Enabled $true `
            -ChangePasswordAtLogon $false -PasswordNeverExpires $true `
            -Description "Utilisateur de test ($($u.Group))."
        Write-Host "User '$($u.Name)' cree dans $($u.OU)." -ForegroundColor Green
    }

    # 2) L'ajouter a son groupe metier (idempotent : -ErrorAction SilentlyContinue)
    Add-ADGroupMember -Identity $u.Group -Members $u.Name -ErrorAction SilentlyContinue
    Write-Host "  -> membre de '$($u.Group)'." -ForegroundColor Green

    # 3) Bonus OpenOffice : ajouter au groupe filtre (le creer si absent)
    if ($u.OpenOffice) {
        if (-not (Get-ADGroup -Filter "Name -eq 'OpenOfficeUsers'" -ErrorAction SilentlyContinue)) {
            New-ADGroup -Name "OpenOfficeUsers" -GroupScope Global -GroupCategory Security `
                -Path $OU_Workspace -Description "Utilisateurs ayant demande OpenOffice (filtrage GPO)."
            Write-Host "  -> groupe 'OpenOfficeUsers' cree." -ForegroundColor Green
        }
        Add-ADGroupMember -Identity "OpenOfficeUsers" -Members $u.Name -ErrorAction SilentlyContinue
        Write-Host "  -> membre de 'OpenOfficeUsers' (demo OpenOffice a la demande)." -ForegroundColor Green
    }
}

# --- VERIFICATION : liste les users de test et leurs groupes ---
Write-Host "`n[VERIFICATION] Utilisateurs de test :" -ForegroundColor Cyan
$report = foreach ($u in $TestUsers) {
    $groups = (Get-ADPrincipalGroupMembership $u.Name | Select-Object -ExpandProperty Name) -join ", "
    [pscustomobject]@{ User = $u.Name; OU = ($u.OU -split ',')[0]; Groupes = $groups }
}
$report | Format-Table -AutoSize -Wrap

Write-Host "Mot de passe commun : $TestUserPassword" -ForegroundColor Magenta
