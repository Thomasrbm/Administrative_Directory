# =============================================================
# main_siem.ps1 - Orchestrateur SIEM : mise en place de l'audit (III.3)
#   Active les sous-categories d'audit + l'audit des dossiers (SACL).
#   Les 5 scripts de LECTURE (III.4) se lancent ensuite a la demande :
#     ListConnectedBetween.ps1   -> qui est connecte entre 2 dates
#     ListUserEvents.ps1         -> evenements d'un utilisateur
#     IsolateFolderAccess.ps1    -> acces/modifs d'un dossier
#     ListUserIPs.ps1            -> IP utilisees par les utilisateurs
#     ListSecurityIncidents.ps1  -> incidents de securite
# =============================================================
$ScriptDir = "$PSScriptRoot"
Write-Host "[1/2] Activation de l'audit..."        -ForegroundColor Cyan; & "$ScriptDir\01_EnableAuditPolicy.ps1"
Write-Host "[2/2] Audit des dossiers (SACL)..."    -ForegroundColor Cyan; & "$ScriptDir\02_EnableFolderAuditing.ps1"
Write-Host "`nAudit en place. Genere de l'activite puis lance les scripts de lecture (voir en-tete)." -ForegroundColor Magenta
