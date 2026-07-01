# =============================================================
# IsolateFolderAccess.ps1 - "Isolate access and modification of one folder" (III.4)
#   Liste les acces/modifs (EventID 4663) sur un dossier.
#   -> Choix du dossier via un MENU (les 5 dossiers du sujet, depuis config.ps1)
#      pour eviter les fautes de frappe.
#   -> Traduit l'AccessMask en lisible (Read/Write/Delete...).
#   PREREQUIS : 02_EnableFolderAuditing.ps1 (sinon aucun 4663 n'existe).
# A lancer en admin sur le DC/serveur de fichiers.
# =============================================================
. "$PSScriptRoot\..\helpers.ps1"
. "$PSScriptRoot\..\config.ps1"
Test-Admin

# --- Choix du dossier via un menu numerote ---
Write-Host "Quel dossier surveiller ?" -ForegroundColor Cyan
for ($i = 0; $i -lt $Folders.Count; $i++) {
    Write-Host ("  [{0}] {1}" -f ($i + 1), $Folders[$i].Path)
}
Write-Host "  [A] Autre (saisie manuelle)"
$choice = Read-Host "Ton choix"

if ($choice -match '^[0-9]+$' -and [int]$choice -ge 1 -and [int]$choice -le $Folders.Count) {
    $Folder = $Folders[[int]$choice - 1].Path
}
else {
    $Folder = Get-Input "Chemin du dossier a surveiller" "Dossier" "D:\WorkPlan"
}
Write-Host "Dossier choisi : $Folder" -ForegroundColor Green

$Start = [datetime](Get-Input "Date/heure DEBUT" "Debut" "2026-07-01 00:00:00")
$End   = [datetime](Get-Input "Date/heure FIN"   "Fin"   "2026-07-01 23:59:59")

# Traduit l'AccessMask (hex) demande en droits lisibles
function Convert-AccessMask {
    param([string]$Hex)
    $m = 0
    try { $m = [Convert]::ToInt32($Hex, 16) } catch { return $Hex }
    $bits = [ordered]@{
        0x1     = "Read/List"
        0x2     = "Write/AddFile"
        0x4     = "Append/AddSubdir"
        0x8     = "ReadEA"
        0x10    = "WriteEA"
        0x20    = "Execute/Traverse"
        0x40    = "DeleteChild"
        0x80    = "ReadAttr"
        0x100   = "WriteAttr"
        0x10000 = "DELETE"
        0x20000 = "ReadPermissions"
        0x40000 = "ChangePermissions"
        0x80000 = "TakeOwnership"
    }
    $names = foreach ($b in $bits.Keys) { if ($m -band $b) { $bits[$b] } }
    if ($names) { $names -join ", " } else { $Hex }
}

# IMPORTANT : sur les disques data, le 4663 enregistre le chemin en format DEVICE
# (ex: \Device\HarddiskVolume8\HumanResources) et non "E:\HumanResources".
# On filtre donc sur la partie du chemin SANS la lettre de lecteur (ex: \HumanResources),
# ce qui matche les deux formats. Pour l'affichage, on reconstruit un chemin lisible.
$drive = $Folder.Substring(0, 2)   # "E:"
$rel   = $Folder.Substring(2)      # "\HumanResources"

# 4663 = tentative d'acces a un objet (lecture/ecriture/suppression selon le masque)
$events = Get-WinEvent -FilterHashtable @{ LogName='Security'; Id=4663; StartTime=$Start; EndTime=$End } -ErrorAction SilentlyContinue |
    Where-Object { $_.Properties[6].Value -like "*$rel*" } |
    ForEach-Object {
        $raw = $_.Properties[6].Value                              # ObjectName (souvent format device)
        $idx = $raw.IndexOf($rel)
        $obj = if ($idx -ge 0) { $drive + $raw.Substring($idx) } else { $raw }  # -> "E:\HumanResources\..."
        [pscustomobject]@{
            Heure  = $_.TimeCreated
            User   = $_.Properties[1].Value                        # SubjectUserName
            Objet  = $obj
            Acces  = Convert-AccessMask $_.Properties[9].Value     # AccessMask -> lisible
        }
    }

Write-Host "`n[RESULTAT] Acces/modifs sur '$Folder' entre $Start et $End :" -ForegroundColor Cyan
$events | Sort-Object Heure | Format-Table -AutoSize -Wrap
Write-Host "Total : $($events.Count) acces." -ForegroundColor Green
