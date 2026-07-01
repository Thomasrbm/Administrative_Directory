# =============================================================
# ListUserEvents.ps1 - "Events concerning one user between 2 time tags" (III.4)
#   Evenements Security d'un utilisateur, avec :
#     - MENU de choix de l'utilisateur (users AD actifs)
#     - MENU de filtre par ACTIVITE (les 7 types du sujet III.3)
#     - LEGENDE Code -> Message a la fin
#   PERFORMANT : periode + utilisateur (+ EventID si une activite est choisie)
#   sont pousses dans la requete (FilterXml). Pas de rendu .Message inutile.
# A lancer en admin sur le DC.
# =============================================================
. "$PSScriptRoot\..\helpers.ps1"
Test-Admin
Import-Module ActiveDirectory -ErrorAction Stop

# --- Reference des 7 activites du sujet (III.3) : type -> { EventID = message } ---
$ActivityTypes = [ordered]@{
    "Computer Account Management" = [ordered]@{
        4741 = "A computer account was created"
        4742 = "A computer account was changed"
        4743 = "A computer account was deleted"
    }
    "Distribution Group Management" = [ordered]@{
        4749 = "A security-disabled global group was created"
        4750 = "A security-disabled global group was changed"
        4751 = "A member was added to a security-disabled global group"
        4752 = "A member was removed from a security-disabled global group"
        4753 = "A security-disabled global group was deleted"
    }
    "Security Group Management" = [ordered]@{
        4727 = "A security-enabled global group was created"
        4728 = "A member was added to a security-enabled global group"
        4729 = "A member was removed from a security-enabled global group"
        4730 = "A security-enabled global group was deleted"
        4735 = "A security-enabled local group was changed"
        4737 = "A security-enabled global group was changed"
    }
    "User Account Management" = [ordered]@{
        4720 = "A user account was created"
        4722 = "A user account was enabled"
        4723 = "An attempt was made to change an account's password"
        4724 = "An attempt was made to reset an account's password"
        4725 = "A user account was disabled"
        4726 = "A user account was deleted"
        4738 = "A user account was changed"
        4740 = "A user account was locked out"
    }
    "Directory Service Access" = [ordered]@{
        4662 = "An operation was performed on an object"
        4661 = "A handle to an object was requested"
    }
    "Logon" = [ordered]@{
        4624 = "An account was successfully logged on"
        4625 = "An account failed to log on"
        4648 = "A logon was attempted using explicit credentials"
    }
    "Logoff" = [ordered]@{
        4634 = "An account was logged off"
        4647 = "User initiated logoff"
    }
}

# Tables de correspondance a plat : code -> message / code -> type
$msgOf = @{}; $typeOf = @{}
foreach ($t in $ActivityTypes.Keys) {
    foreach ($id in $ActivityTypes[$t].Keys) { $msgOf[$id] = $ActivityTypes[$t][$id]; $typeOf[$id] = $t }
}

# --- Menu : filtrer par activite ---
$typeNames = @($ActivityTypes.Keys)
Write-Host "Filtrer par quelle activite ?" -ForegroundColor Cyan
for ($i = 0; $i -lt $typeNames.Count; $i++) {
    Write-Host ("  [{0}] {1}" -f ($i + 1), $typeNames[$i])
}
Write-Host "  [A] Toutes les activites"
$tc = Read-Host "Ton choix"
if ($tc -match '^[0-9]+$' -and [int]$tc -ge 1 -and [int]$tc -le $typeNames.Count) {
    $selType = $typeNames[[int]$tc - 1]
    $ids = @($ActivityTypes[$selType].Keys)
}
else {
    $selType = "Toutes les activites"
    $ids = @()
}
Write-Host "Activite : $selType" -ForegroundColor Green

# --- Menu : choix de l'utilisateur ---
$users = Get-ADUser -Filter 'Enabled -eq $true' | Select-Object -ExpandProperty SamAccountName | Sort-Object
Write-Host "`nQuel utilisateur ?" -ForegroundColor Cyan
for ($i = 0; $i -lt $users.Count; $i++) {
    Write-Host ("  [{0}] {1}" -f ($i + 1), $users[$i])
}
Write-Host "  [A] Autre (saisie manuelle)"
$uc = Read-Host "Ton choix"
if ($uc -match '^[0-9]+$' -and [int]$uc -ge 1 -and [int]$uc -le $users.Count) {
    $User = $users[[int]$uc - 1]
}
else {
    $User = Get-Input "SamAccountName de l'utilisateur" "Utilisateur" "worker1"
}
Write-Host "Utilisateur : $User" -ForegroundColor Green

$Start = [datetime](Get-Input "Date/heure DEBUT" "Debut" "2026-07-01 00:00:00")
$End   = [datetime](Get-Input "Date/heure FIN"   "Fin"   "2026-07-01 23:59:59")

# Bornes en UTC (format XPath)
$sUtc = $Start.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
$eUtc = $End.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")

# Clause System : periode (+ EventID si une activite precise est choisie)
$sys = "TimeCreated[@SystemTime&gt;='$sUtc' and @SystemTime&lt;='$eUtc']"
if ($ids.Count) {
    $idClause = ($ids | ForEach-Object { "EventID=$_" }) -join " or "
    $sys += " and ($idClause)"
}

# Requete : filtre a la SOURCE (periode + activite + user = auteur OU cible)
$xml = @"
<QueryList>
  <Query Id="0" Path="Security">
    <Select Path="Security">
      *[System[$sys]]
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
            Heure  = $_.TimeCreated
            Code   = $_.Id
            Type   = if ($typeOf.ContainsKey([int]$_.Id)) { $typeOf[[int]$_.Id] } else { '-' }
            Action = ($_.Message -split "`r?`n")[0]
        }
    }

Write-Host "`n[RESULTAT] Activite '$selType' pour '$User' entre $Start et $End :" -ForegroundColor Cyan
$events | Sort-Object Heure | Format-Table -AutoSize -Wrap
Write-Host "Total : $($events.Count) evenement(s)." -ForegroundColor Green

# --- LEGENDE : quel code correspond a quoi ---
Write-Host "`n[LEGENDE] Codes et leur signification :" -ForegroundColor Cyan
if ($ids.Count) {
    # Activite precise -> reference complete de cette activite
    $legend = $ids | Sort-Object | ForEach-Object {
        [pscustomobject]@{ Code = $_; Activite = $selType; Message = $ActivityTypes[$selType][$_] }
    }
}
else {
    # Toutes -> uniquement les codes rencontres dans les resultats
    $legend = $events | Select-Object -ExpandProperty Code -Unique | Sort-Object | ForEach-Object {
        [pscustomobject]@{
            Code     = $_
            Activite = if ($typeOf.ContainsKey([int]$_)) { $typeOf[[int]$_] } else { '(hors des 7 activites)' }
            Message  = if ($msgOf.ContainsKey([int]$_))  { $msgOf[[int]$_] }  else { '' }
        }
    }
}
$legend | Format-Table -AutoSize -Wrap
