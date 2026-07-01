# =============================================================
# 03_InitDisks.ps1 - Prepare les disques "D:" et "E:" (III.1)
#   Initialise les disques bruts (RAW) ajoutes a la VM, cree une partition
#   NTFS et lui attribue la lettre D: puis E:.
#
# PREREQUIS : avoir ajoute 2 disques virtuels a la VM (cote hyperviseur/portail).
# NOTE Azure : la lettre D: est parfois prise par le "temporary disk". Si c'est
#              le cas, ce script previent et n'ecrase RIEN (a regler a la main).
# =============================================================
. "$PSScriptRoot\..\helpers.ps1"
. "$PSScriptRoot\..\config.ps1"
Test-Admin

# On veut ces lettres, dans cet ordre :
$TargetLetters = @("D", "E")

foreach ($letter in $TargetLetters) {
    # Deja un volume avec cette lettre ? on ne touche pas.
    if (Get-Volume -DriveLetter $letter -ErrorAction SilentlyContinue) {
        Write-Host "Le volume ${letter}: existe deja (non modifie)." -ForegroundColor Yellow
        continue
    }

    # Premier disque encore brut (RAW = jamais initialise)
    $raw = Get-Disk | Where-Object PartitionStyle -eq 'RAW' | Sort-Object Number | Select-Object -First 1
    if (-not $raw) {
        Write-Host "Aucun disque brut disponible pour ${letter}: (ajoute un disque a la VM)." -ForegroundColor Red
        continue
    }

    Write-Host "Initialisation du disque #$($raw.Number) -> ${letter}:" -ForegroundColor Cyan
    Initialize-Disk -Number $raw.Number -PartitionStyle GPT -ErrorAction Stop
    New-Partition -DiskNumber $raw.Number -UseMaximumSize -DriveLetter $letter |
        Format-Volume -FileSystem NTFS -NewFileSystemLabel "DATA_$letter" -Confirm:$false | Out-Null
    Write-Host "Disque ${letter}: pret." -ForegroundColor Green
}

# --- VERIFICATION : liste les volumes D: et E: ---
Write-Host "`n[VERIFICATION] Volumes D: et E: :" -ForegroundColor Cyan
Get-Volume -DriveLetter D, E -ErrorAction SilentlyContinue |
    Select-Object DriveLetter, FileSystemLabel, FileSystem, @{N='SizeGB';E={[math]::Round($_.Size/1GB,1)}} |
    Format-Table -AutoSize
