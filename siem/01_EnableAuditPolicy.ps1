# =============================================================
# 01_EnableAuditPolicy.ps1 - Active l'audit des activites demandees (III.3)
#   Le "SIEM" du sujet = journalisation Windows. On active les sous-categories
#   d'audit correspondant aux 7 activites listees, en succes ET echec.
#   auditpol applique immediatement (pas de reboot). A lancer sur SRV-ADMIN (DC).
# =============================================================
. "$PSScriptRoot\..\helpers.ps1"
Test-Admin

# Les 7 activites du sujet -> sous-categories d'audit Windows exactes
$Subcategories = @(
    "Computer Account Management"      # Comptes ordinateurs (4741/4742/4743)
    "Distribution Group Management"    # Groupes de distribution (4744/4749/4750...)
    "Security Group Management"        # Groupes de securite (4727/4728/4729/4731...)
    "User Account Management"          # Comptes utilisateurs (4720/4722/4725/4726...)
    "Directory Service Access"         # Acces annuaire (4662)
    "Logon"                            # Connexions (4624 / echec 4625)
    "Logoff"                           # Deconnexions (4634/4647)
)

# S'assurer que Windows respecte les sous-categories (et pas la vieille politique
# globale). C'est un reglage de REGISTRE (defaut = 1 sur Server 2016+), on le force.
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Lsa" `
    -Name "SCENoApplyLegacyAuditPolicy" -Value 1 -Type DWord -ErrorAction SilentlyContinue

foreach ($sub in $Subcategories) {
    auditpol /set /subcategory:"$sub" /success:enable /failure:enable | Out-Null
    Write-Host "Audit active : $sub" -ForegroundColor Green
}

# --- VERIFICATION : relit l'etat de chaque sous-categorie ---
Write-Host "`n[VERIFICATION] Etat de l'audit :" -ForegroundColor Cyan
foreach ($sub in $Subcategories) {
    auditpol /get /subcategory:"$sub" | Select-String $sub
}
