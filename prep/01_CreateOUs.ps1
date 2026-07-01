# =============================================================
# 01_CreateOUs.ps1 - Cree les OU "Workspace" et "Administration" (III.1)
# A lancer en admin sur SRV-ADMIN (le DC).
# =============================================================
. "$PSScriptRoot\..\helpers.ps1"
. "$PSScriptRoot\..\config.ps1"
Test-Admin

foreach ($name in @("Workspace", "Administration")) {
    # -ProtectedFromAccidentalDeletion $false : sinon impossible a supprimer/reset facilement
    if (Get-ADOrganizationalUnit -Filter "Name -eq '$name'" -ErrorAction SilentlyContinue) {
        Write-Host "OU '$name' existe deja." -ForegroundColor Yellow
    } else {
        New-ADOrganizationalUnit -Name $name -Path $DomainDN -ProtectedFromAccidentalDeletion $false
        Write-Host "OU '$name' creee." -ForegroundColor Green
    }
}

# --- VERIFICATION : on relit les OU dans l'annuaire ---
Write-Host "`n[VERIFICATION] OU presentes sous $DomainDN :" -ForegroundColor Cyan
Get-ADOrganizationalUnit -Filter * -SearchBase $DomainDN -SearchScope OneLevel |
    Select-Object Name, DistinguishedName | Format-Table -AutoSize
