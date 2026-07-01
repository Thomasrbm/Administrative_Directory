# =============================================================
# ListUserIPs.ps1 - "List of IPs used by users" (III.4)
#   Pour chaque utilisateur, les adresses IP source de ses connexions (4624).
# A lancer en admin sur le DC.
# =============================================================
. "$PSScriptRoot\..\helpers.ps1"
Test-Admin

$Start = [datetime](Get-Input "Date/heure DEBUT" "Debut" "2026-07-01 00:00:00")
$End   = [datetime](Get-Input "Date/heure FIN"   "Fin"   "2026-07-01 23:59:59")

$rows = Get-WinEvent -FilterHashtable @{ LogName='Security'; Id=4624; StartTime=$Start; EndTime=$End } -ErrorAction SilentlyContinue |
    ForEach-Object {
        [pscustomobject]@{
            User = $_.Properties[5].Value     # TargetUserName
            IP   = $_.Properties[18].Value    # IpAddress
        }
    } |
    # on ecarte comptes machine/systeme et IP vides ou locales "-"
    Where-Object { $_.User -notlike '*$' -and $_.User -ne 'SYSTEM' -and $_.IP -and $_.IP -ne '-' -and $_.IP -ne '::1' -and $_.IP -ne '127.0.0.1' }

Write-Host "`n[RESULTAT] IP utilisees par utilisateur :" -ForegroundColor Cyan
$rows | Group-Object User | ForEach-Object {
    [pscustomobject]@{
        User = $_.Name
        IPs  = ($_.Group.IP | Sort-Object -Unique) -join ", "
    }
} | Format-Table -AutoSize -Wrap
