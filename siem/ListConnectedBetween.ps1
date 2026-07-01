# =============================================================
# ListConnectedBetween.ps1 - "Who's connected between 2 time tags" (III.4)
#   Liste les connexions reussies (EventID 4624) entre deux dates.
# A lancer en admin sur le DC (lecture du journal Security).
# =============================================================
. "$PSScriptRoot\..\helpers.ps1"
Test-Admin

$Start = [datetime](Get-Input "Date/heure DEBUT (ex: 2026-07-01 08:00:00)" "Debut" "2026-07-01 00:00:00")
$End   = [datetime](Get-Input "Date/heure FIN   (ex: 2026-07-01 18:00:00)" "Fin"   "2026-07-01 23:59:59")

# 4624 = ouverture de session reussie. On ignore les comptes systeme/machine ($ et SYSTEM).
$events = Get-WinEvent -FilterHashtable @{ LogName='Security'; Id=4624; StartTime=$Start; EndTime=$End } -ErrorAction SilentlyContinue |
    ForEach-Object {
        [pscustomobject]@{
            Heure     = $_.TimeCreated
            User      = $_.Properties[5].Value      # TargetUserName
            Domaine   = $_.Properties[6].Value      # TargetDomainName
            TypeLogon = $_.Properties[8].Value       # LogonType (2=local,3=reseau,10=RDP...)
            IP        = $_.Properties[18].Value       # IpAddress
        }
    } | Where-Object { $_.User -notlike '*$' -and $_.User -ne 'SYSTEM' -and $_.User -ne 'ANONYMOUS LOGON' }

Write-Host "`n[RESULTAT] Connexions entre $Start et $End :" -ForegroundColor Cyan
$events | Sort-Object Heure | Format-Table -AutoSize
Write-Host "Total : $($events.Count) connexion(s)." -ForegroundColor Green
