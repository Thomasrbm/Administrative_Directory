# =============================================================
# 02_GPO_DriveMaps.ps1 - GPO Drive Maps (III.2)
#   "Allow groups to access certain disk, and automatically connect to them.
#    Every group should access the two mandatory disks."
#
#   Vraie Group Policy PREFERENCE (Drive Maps) : on genere le Drives.xml dans
#   SYSVOL, on enregistre l'extension cliente (CSE) sur l'objet GPO, et on
#   incremente la version pour que les clients reappliquent. Mappe 2 lecteurs
#   reseau (S: et T:) vers les deux disques partages, pour TOUS les utilisateurs.
# =============================================================
. "$PSScriptRoot\..\helpers.ps1"
. "$PSScriptRoot\..\config.ps1"
Test-Admin
Import-Module GroupPolicy   -ErrorAction Stop
Import-Module ActiveDirectory -ErrorAction Stop

$GpoName = "DriveMaps - Disques D et E"
$Server  = Get-Input "Nom du serveur hebergeant les disques (partages)" "Serveur de fichiers" "SRV-ADMIN"

# 1) Partager les racines des disques (necessaire pour un mappage reseau)
foreach ($d in @(@{L="D"; S="Disk-D"}, @{L="E"; S="Disk-E"})) {
    if (Get-Volume -DriveLetter $d.L -ErrorAction SilentlyContinue) {
        Publish-Share "$($d.L):\" $d.S
    } else {
        Write-Host "Disque $($d.L): absent : lance prep\03_InitDisks.ps1 d'abord." -ForegroundColor Red
    }
}

# 2) Creer la GPO si absente
$gpo = Get-GPO -Name $GpoName -ErrorAction SilentlyContinue
if (-not $gpo) { $gpo = New-GPO -Name $GpoName; Write-Host "GPO creee." -ForegroundColor Green }
$Guid = "{$($gpo.Id)}"

# 3) Ecrire Drives.xml dans SYSVOL (partie User > Preferences > Drive Maps)
$DrivesDir = "\\$Domain\SYSVOL\$Domain\Policies\$Guid\User\Preferences\Drives"
New-Item -ItemType Directory -Path $DrivesDir -Force | Out-Null
$Now = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")

# Deux mappages : S: -> disque D, T: -> disque E. action="U" (Update/Create),
# persistent + useLetter pour forcer la lettre et la reconnexion automatique.
$maps = @(
    @{ Letter="S"; Share="Disk-D"; Label="Disque D (Domolia)" }
    @{ Letter="T"; Share="Disk-E"; Label="Disque E (Domolia)" }
)
$items = foreach ($m in $maps) {
    $uid = "{$([guid]::NewGuid())}"
@"
	<Drive clsid="{935D1B74-9CB8-4e3c-9914-7DD559B7A417}" name="$($m.Letter):" status="$($m.Letter):" image="2" changed="$Now" uid="$uid">
		<Properties action="U" thisDrive="NOCHANGE" allDrives="NOCHANGE" userName="" path="\\$Server\$($m.Share)" label="$($m.Label)" persistent="1" useLetter="1" letter="$($m.Letter)"/>
	</Drive>
"@
}
$xml = @"
<?xml version="1.0" encoding="utf-8"?>
<Drives clsid="{8FDDCC1A-0C3C-43cd-A6B4-71A6DF20DA8C}">
$($items -join "`r`n")
</Drives>
"@
Set-Content -Path "$DrivesDir\Drives.xml" -Value $xml -Encoding UTF8
Write-Host "Drives.xml ecrit dans SYSVOL." -ForegroundColor Green

# 4) Enregistrer l'extension cliente Drive Maps (sinon le client ignore le xml)
#    CSE Drive Maps = {5794DAFD-...}, outil MMC Preferences = {2EA1A81B-...}
$cse = "[{00000000-0000-0000-0000-000000000000}{2EA1A81B-48E5-45E9-8BB7-A6E3AC170006}][{5794DAFD-BE60-433f-88A2-1A31939AC01F}{2EA1A81B-48E5-45E9-8BB7-A6E3AC170006}]"
Set-ADObject -Identity $gpo.Path -Replace @{ gPCUserExtensionNames = $cse }

# 5) Incrementer la version (partie User = 16 bits de poids fort) : AD + GPT.ini
$obj = Get-ADObject -Identity $gpo.Path -Properties versionNumber
$ver = [int]$obj.versionNumber
$new = ((($ver -shr 16) + 1) -shl 16) -bor ($ver -band 0xFFFF)
Set-ADObject -Identity $gpo.Path -Replace @{ versionNumber = $new }
$gptIni = "\\$Domain\SYSVOL\$Domain\Policies\$Guid\GPT.ini"
(Get-Content $gptIni) -replace 'Version=\d+', "Version=$new" | Set-Content $gptIni
Write-Host "Extension cliente enregistree + version -> $new." -ForegroundColor Green

# 6) Lier aux deux OU (tout le monde recoit les 2 lecteurs)
foreach ($ou in @($OU_Workspace, $OU_Administration)) {
    New-GPLink -Name $GpoName -Target $ou -LinkEnabled Yes -ErrorAction SilentlyContinue | Out-Null
    Write-Host "GPO liee a $ou" -ForegroundColor Green
}

# --- VERIFICATION ---
Write-Host "`n[VERIFICATION] Drives.xml :" -ForegroundColor Cyan
Get-Content "$DrivesDir\Drives.xml"
Write-Host "`nSur un client : gpupdate /force puis re-login -> lecteurs S: et T: montes." -ForegroundColor Yellow
