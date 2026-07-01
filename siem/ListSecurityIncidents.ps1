# =============================================================
# ListSecurityIncidents.ps1 - "List security incidents" (III.4)
#   Regroupe les evenements sensibles : echecs de connexion, verrouillages,
#   effacement de journal, changement de politique d'audit, etc.
# A lancer en admin sur le DC.
# =============================================================
. "$PSScriptRoot\..\helpers.ps1"
Test-Admin

$Start = [datetime](Get-Input "Date/heure DEBUT" "Debut" "2026-07-01 00:00:00")
$End   = [datetime](Get-Input "Date/heure FIN"   "Fin"   "2026-07-01 23:59:59")

# EventID consideres comme "incidents de securite" + libelle lisible
$Incidents = @{
    4625 = "Echec d'ouverture de session"
    4740 = "Compte verrouille"
    4771 = "Echec pre-authentification Kerberos"
    4648 = "Connexion avec identifiants explicites"
    4723 = "Tentative de changement de mot de passe"
    4724 = "Reinitialisation de mot de passe"
    1102 = "Journal de securite efface"
    4719 = "Politique d'audit systeme modifiee"
    4735 = "Groupe de securite modifie"
}

$ids = $Incidents.Keys
$events = Get-WinEvent -FilterHashtable @{ LogName='Security'; Id=$ids; StartTime=$Start; EndTime=$End } -ErrorAction SilentlyContinue |
    ForEach-Object {
        [pscustomobject]@{
            Heure   = $_.TimeCreated
            EventID = $_.Id
            Type    = $Incidents[[int]$_.Id]
            User    = $_.Properties[5].Value    # cible selon l'event (best effort)
        }
    }

Write-Host "`n[RESULTAT] Incidents de securite entre $Start et $End :" -ForegroundColor Cyan
$events | Sort-Object Heure | Format-Table -AutoSize -Wrap
Write-Host "`n[SYNTHESE] par type :" -ForegroundColor Cyan
$events | Group-Object Type | Select-Object Count, Name | Sort-Object Count -Descending | Format-Table -AutoSize
Write-Host "Total : $($events.Count) incident(s)." -ForegroundColor Green
