# =============================================================
# ListUserEvents.ps1 - "Events concerning one user between 2 time tags" (III.4)
#   Tous les evenements Security ou l'utilisateur donne apparait, sur une periode.
#   -> Choix de l'utilisateur via un MENU (users AD actifs).
#   -> PERFORMANT : le filtre par utilisateur est pousse dans la requete (FilterXml)
#      au lieu de rendre le .Message de chaque evenement (ce qui rendait le script
#      quasi infini sur un DC).
# A lancer en admin sur le DC.
# =============================================================
. "$PSScriptRoot\..\helpers.ps1"
Test-Admin
Import-Module ActiveDirectory -ErrorAction Stop

# --- Choix de l'utilisateur via un menu ---
$users = Get-ADUser -Filter 'Enabled -eq $true' |
    Select-Object -ExpandProperty SamAccountName | Sort-Object

Write-Host "Quel utilisateur ?" -ForegroundColor Cyan
for ($i = 0; $i -lt $users.Count; $i++) {
    Write-Host ("  [{0}] {1}" -f ($i + 1), $users[$i])
}
Write-Host "  [A] Autre (saisie manuelle)"
$choice = Read-Host "Ton choix"

if ($choice -match '^[0-9]+$' -and [int]$choice -ge 1 -and [int]$choice -le $users.Count) {
    $User = $users[[int]$choice - 1]
}
else {
    $User = Get-Input "SamAccountName de l'utilisateur" "Utilisateur" "worker1"
}
Write-Host "Utilisateur choisi : $User" -ForegroundColor Green

$Start = [datetime](Get-Input "Date/heure DEBUT" "Debut" "2026-07-01 00:00:00")
$End   = [datetime](Get-Input "Date/heure FIN"   "Fin"   "2026-07-01 23:59:59")

# Bornes en UTC (format attendu par XPath)
$sUtc = $Start.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
$eUtc = $End.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")

# Requete filtrant a la SOURCE : periode + (user = auteur OU cible de l'action).
# -> ne remonte QUE les evenements de l'utilisateur = rapide.
$xml = @"
<QueryList>
  <Query Id="0" Path="Security">
    <Select Path="Security">
      *[System[TimeCreated[@SystemTime&gt;='$sUtc' and @SystemTime&lt;='$eUtc']]]
      and
      (
        *[EventData[Data[@Name='TargetUserName']='$User']]
        or *[EventData[Data[@Name='SubjectUserName']='$User']]
      )
    </Select>
  </Query>
</QueryList>
"@

$events = Get-WinEvent -FilterXml $xml -MaxEvents 1000 -ErrorAction SilentlyContinue |
    ForEach-Object {
        [pscustomobject]@{
            Heure   = $_.TimeCreated
            EventID = $_.Id
            Action  = ($_.Message -split "`r?`n")[0]   # 1re ligne = libelle (rendu sur le petit set only)
        }
    }

Write-Host "`n[RESULTAT] Evenements concernant '$User' entre $Start et $End :" -ForegroundColor Cyan
$events | Sort-Object Heure | Format-Table -AutoSize -Wrap
Write-Host "Total : $($events.Count) evenement(s) (max 1000 affiches)." -ForegroundColor Green
