# =============================================================
# 03_InitDisks.ps1 - Prepare les volumes "D:" et "E:" (III.1)
#   Initialise les 2 disques data (RAW) ajoutes a la VM et leur donne
#   la lettre D: puis E:.
#
#   ROBUSTE AZURE : sur les VM Azure, la lettre D: est prise par le
#   "disque temporaire" (label "Temporary Storage", pagefile dessus).
#   Ce script le detecte et le DEPLACE automatiquement vers une autre
#   lettre (Z:, Y:...) pour liberer D:/E: sans rien casser.
#   Si le pagefile empeche le deplacement a chaud, il previent et
#   demande un simple redemarrage + relance (idempotent).
# =============================================================
. "$PSScriptRoot\..\helpers.ps1"
. "$PSScriptRoot\..\config.ps1"
Test-Admin

# On veut ces lettres, dans cet ordre :
$TargetLetters = @("D", "E")

# Renvoie une lettre libre en partant de Z: vers le bas (pour reloger le
# disque temporaire), en evitant D:/E: qu'on reserve aux disques data.
function Get-FreeDriveLetter {
    foreach ($code in 90..67) {                       # Z .. C
        $l = [string][char]$code
        if ($TargetLetters -contains $l) { continue }
        if (-not (Get-Volume -DriveLetter $l -ErrorAction SilentlyContinue)) { return $l }
    }
    return $null
}

# --- 1) Liberer D:/E: si elles sont prises par le disque temporaire Azure ---
foreach ($letter in $TargetLetters) {
    $vol = Get-Volume -DriveLetter $letter -ErrorAction SilentlyContinue
    if (-not $vol) { continue }

    if ($vol.FileSystemLabel -eq 'Temporary Storage') {
        $free = Get-FreeDriveLetter
        Write-Host "Disque temporaire Azure sur ${letter}: -> deplacement vers ${free}:" -ForegroundColor Yellow

        # Le pagefile est sur le disque temporaire : on le confie a Windows (C:)
        # pour pouvoir liberer la lettre.
        $cs = Get-CimInstance Win32_ComputerSystem
        if (-not $cs.AutomaticManagedPagefile) {
            $cs | Set-CimInstance -Property @{ AutomaticManagedPagefile = $true } -ErrorAction SilentlyContinue
            Write-Host "Pagefile confie a Windows (auto)." -ForegroundColor Yellow
        }
        Get-CimInstance Win32_PageFileSetting -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -like "${letter}:*" } |
            ForEach-Object { Remove-CimInstance -InputObject $_ -ErrorAction SilentlyContinue }

        try {
            Get-Partition -DriveLetter $letter | Set-Partition -NewDriveLetter $free -ErrorAction Stop
            Write-Host "Disque temporaire deplace en ${free}:. ${letter}: est libre." -ForegroundColor Green
        }
        catch {
            Write-Host "Impossible de liberer ${letter}: a chaud (pagefile encore actif)." -ForegroundColor Red
            Write-Host ">>> REDEMARRE la VM (Restart-Computer) puis relance ce script : <<<" -ForegroundColor Red
            Write-Host ">>> la lettre ${letter}: sera alors libre et l'init se fera.       <<<" -ForegroundColor Red
        }
    }
    else {
        Write-Host "Le volume ${letter}: existe deja (non temporaire) - non modifie." -ForegroundColor Yellow
    }
}

# --- 2) Initialiser les disques bruts (RAW) -> D: puis E: -------------------
foreach ($letter in $TargetLetters) {
    # Deja un volume avec cette lettre (data deja pret) ? on ne touche pas.
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
