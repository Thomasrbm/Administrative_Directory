# =============================================================
# Fix-OpenOfficeMsi.ps1 - Rend le MSI LibreOffice compatible GPO Software Installation
#
#   PROBLEME : le MSI LibreOffice declare enormement de langues -> le champ
#   "Languages" du Summary Information depasse 254 caracteres, et la GPO
#   Software Installation ne peut pas le parser :
#     "Add operation failed. Unable to extract deployment information from the package."
#
#   FIX : on raccourcit la liste de langues du Summary Information a l'anglais
#   (1033). Ca ne change que la langue de l'INSTALLEUR, pas de LibreOffice.
#
#   Idempotent : relancable sans risque.
#   Appele automatiquement par 00_DownloadInstallers.ps1, ou lancable seul.
# =============================================================
. "$PSScriptRoot\..\config.ps1"

$msi = "\\$Domain\SYSVOL\$Domain\installers\OpenOffice.msi"

if (-not (Test-Path $msi)) {
    Write-Host "Introuvable : $msi (lance d'abord 00_DownloadInstallers.ps1)." -ForegroundColor Red
    return
}

try {
    $wi = New-Object -ComObject WindowsInstaller.Installer

    # Ouvre le Summary Information en ecriture (updateCount > 0)
    $si = $wi.GetType().InvokeMember('SummaryInformation','GetProperty',$null,$wi,@($msi,20))

    # Propriete 7 = PID_TEMPLATE, format "plateforme;listeDeLangues"
    $tpl = $si.GetType().InvokeMember('Property','GetProperty',$null,$si,@(7))
    $platform = ($tpl -split ';')[0]
    $new = "$platform;1033"

    if ($tpl -eq $new) {
        Write-Host "OpenOffice.msi deja patche ($tpl)." -ForegroundColor Yellow
    }
    else {
        Write-Host "Template avant : $tpl" -ForegroundColor Yellow
        $si.GetType().InvokeMember('Property','SetProperty',$null,$si,@(7,$new))
        $si.GetType().InvokeMember('Persist','InvokeMethod',$null,$si,$null)
        Write-Host "Template apres : $new  -> MSI patche, pret pour la GPO." -ForegroundColor Green
    }

    # Libere le handle pour que la GPO puisse relire le fichier
    $si = $null
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($wi) | Out-Null
    [GC]::Collect()
}
catch {
    Write-Host "Echec du patch : $($_.Exception.Message)" -ForegroundColor Red
}
