# =============================================================
# 00_DownloadInstallers.ps1 - Telecharge les MSI a deployer (Slack + OpenOffice)
#   Cree le dossier partage "installers" dans SYSVOL (deja lisible par
#   Domain Computers / Authenticated Users) et y depose les .msi.
#
#   NB OpenOffice : Apache OpenOffice ne fournit PAS de vrai .msi (que du .exe).
#   On prend donc LibreOffice (vrai .msi officiel, equivalent fonctionnel) mais
#   on le nomme "OpenOffice.msi" pour rester compatible avec les GPO existantes.
#
#   PREREQUIS : la VM doit avoir un acces Internet.
#   A lancer en admin sur SRV-ADMIN.
# =============================================================
. "$PSScriptRoot\..\config.ps1"

# TLS 1.2 obligatoire pour ces sites (sinon Invoke-WebRequest echoue)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$installers = "\\$Domain\SYSVOL\$Domain\installers"
New-Item -ItemType Directory -Path $installers -Force | Out-Null
Write-Host "Dossier prepare : $installers" -ForegroundColor Cyan

# --- URLs de telechargement ---
# Slack : lien "machine-wide MSI" officiel (suit une redirection vers le .msi).
# LibreOffice : URL VERSIONNEE -> si le telechargement echoue (404), mets a jour
#   $LoVersion avec une version existante (voir download.documentfoundation.org).
$LoVersion = "24.8.4"
$downloads = @(
    @{ Name = "Slack.msi";      Url = "https://slack.com/ssb/download-win64-msi" }
    @{ Name = "OpenOffice.msi"; Url = "https://download.documentfoundation.org/libreoffice/stable/$LoVersion/win/x86_64/LibreOffice_${LoVersion}_Win_x86-64.msi" }
)

foreach ($d in $downloads) {
    $dest = Join-Path $installers $d.Name
    if (Test-Path $dest) {
        Write-Host "$($d.Name) deja present, on garde." -ForegroundColor Yellow
        continue
    }
    try {
        Write-Host "Telechargement de $($d.Name)..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $d.Url -OutFile $dest -UseBasicParsing
        $sizeMB = [math]::Round((Get-Item $dest).Length / 1MB, 1)
        Write-Host "OK : $($d.Name) ($sizeMB Mo) -> $dest" -ForegroundColor Green
    }
    catch {
        Write-Host "ECHEC pour $($d.Name) : $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "  -> Telecharge-le a la main et depose-le dans $installers" -ForegroundColor Yellow
        if ($d.Name -eq "OpenOffice.msi") {
            Write-Host "  -> (LibreOffice: verifie/ajuste la version dans `$LoVersion en haut du script)" -ForegroundColor Yellow
        }
    }
}

# --- VERIFICATION ---
Write-Host "`n[VERIFICATION] Contenu de installers :" -ForegroundColor Cyan
Get-ChildItem $installers -ErrorAction SilentlyContinue |
    Select-Object Name, @{N='Mo';E={[math]::Round($_.Length/1MB,1)}} | Format-Table -AutoSize
