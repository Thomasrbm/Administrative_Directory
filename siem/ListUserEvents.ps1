# =============================================================
# ListUserEvents.ps1 - "Events concerning one user between 2 time tags" (III.4)
#   Tous les evenements Security ou l'utilisateur donne apparait, sur une periode.
# A lancer en admin sur le DC.
# =============================================================
. "$PSScriptRoot\..\helpers.ps1"
Test-Admin

$User  = Get-Input "Utilisateur cible (SamAccountName, ex: user.worker)" "Utilisateur" "user.worker"
$Start = [datetime](Get-Input "Date/heure DEBUT" "Debut" "2026-07-01 00:00:00")
$End   = [datetime](Get-Input "Date/heure FIN"   "Fin"   "2026-07-01 23:59:59")

# On recupere la periode puis on garde les evenements qui mentionnent l'utilisateur
# (le nom peut etre l'auteur OU la cible de l'action selon l'EventID).
$events = Get-WinEvent -FilterHashtable @{ LogName='Security'; StartTime=$Start; EndTime=$End } -ErrorAction SilentlyContinue |
    Where-Object { $_.Properties.Value -contains $User -or $_.Message -match [regex]::Escape($User) } |
    ForEach-Object {
        [pscustomobject]@{
            Heure   = $_.TimeCreated
            EventID = $_.Id
            Action  = ($_.Message -split "`n")[0]   # 1re ligne = libelle de l'action
        }
    }

Write-Host "`n[RESULTAT] Evenements concernant '$User' entre $Start et $End :" -ForegroundColor Cyan
$events | Sort-Object Heure | Format-Table -AutoSize -Wrap
Write-Host "Total : $($events.Count) evenement(s)." -ForegroundColor Green
