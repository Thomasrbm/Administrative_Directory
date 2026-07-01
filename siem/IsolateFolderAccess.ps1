# =============================================================
# IsolateFolderAccess.ps1 - "Isolate access and modification of one folder" (III.4)
#   Liste les acces/modifs (EventID 4663) + suppressions (4660) sur un dossier.
#   PREREQUIS : 02_EnableFolderAuditing.ps1 (sinon aucun 4663 n'existe).
# A lancer en admin sur le DC/serveur de fichiers.
# =============================================================
. "$PSScriptRoot\..\helpers.ps1"
Test-Admin

$Folder = Get-Input "Dossier a surveiller (ex: E:\HumanResources)" "Dossier" "E:\HumanResources"
$Start  = [datetime](Get-Input "Date/heure DEBUT" "Debut" "2026-07-01 00:00:00")
$End    = [datetime](Get-Input "Date/heure FIN"   "Fin"   "2026-07-01 23:59:59")

# 4663 = tentative d'acces a un objet (lecture/ecriture/suppression selon le masque)
$events = Get-WinEvent -FilterHashtable @{ LogName='Security'; Id=4663; StartTime=$Start; EndTime=$End } -ErrorAction SilentlyContinue |
    ForEach-Object {
        [pscustomobject]@{
            Heure  = $_.TimeCreated
            User   = $_.Properties[1].Value    # SubjectUserName
            Objet  = $_.Properties[6].Value    # ObjectName (chemin du fichier/dossier)
            Acces  = $_.Properties[8].Value     # AccessMask demande
        }
    } | Where-Object { $_.Objet -like "$Folder*" }

Write-Host "`n[RESULTAT] Acces/modifs sur '$Folder' entre $Start et $End :" -ForegroundColor Cyan
$events | Sort-Object Heure | Format-Table -AutoSize
Write-Host "Total : $($events.Count) acces." -ForegroundColor Green
