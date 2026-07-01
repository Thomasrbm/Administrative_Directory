# =============================================================
# 06_EnableRemoteLogin.ps1 - Autorise le RDP pour les users de test
#   Probleme : sur un CONTROLEUR DE DOMAINE, seuls les Administrateurs ont le
#   droit "Allow log on through Remote Desktop Services" (SeRemoteInteractiveLogonRight).
#   Les utilisateurs standard sont donc refuses en RDP ("not authorized for remote login").
#
#   Solution :
#     1) ajouter les users de test au groupe "Remote Desktop Users"
#     2) accorder ce droit RDP au groupe "Remote Desktop Users" DANS la
#        "Default Domain Controllers Policy" (sinon le DC continue de bloquer)
#     3) gpupdate pour appliquer tout de suite
#
#   /!\ En prod on ne donne PAS le RDP aux users sur un DC ; ici c'est un lab
#       mono-serveur, donc on assume ce choix pour pouvoir tester.
# A lancer en admin sur SRV-ADMIN (le DC).
# =============================================================
. "$PSScriptRoot\..\helpers.ps1"
. "$PSScriptRoot\..\config.ps1"
Test-Admin
Import-Module ActiveDirectory -ErrorAction Stop

# --- 1) Ajouter les users de test au groupe "Remote Desktop Users" ----------
foreach ($u in $TestUsers) {
    Add-ADGroupMember -Identity "Remote Desktop Users" -Members $u.Name -ErrorAction SilentlyContinue
    Write-Host "'$($u.Name)' ajoute a 'Remote Desktop Users'." -ForegroundColor Green
}

# --- 2) Accorder le droit RDP dans la Default Domain Controllers Policy ------
# GUID connu (identique dans tous les domaines AD) de la Default Domain Controllers Policy.
$DDCP = "{6AC1786C-016F-11D2-945F-00C04FB984F9}"
$inf  = "\\$Domain\SYSVOL\$Domain\Policies\$DDCP\MACHINE\Microsoft\Windows NT\SecEdit\GptTmpl.inf"

# Administrators (*S-1-5-32-544) + Remote Desktop Users (*S-1-5-32-555)
$rightLine = "SeRemoteInteractiveLogonRight = *S-1-5-32-544,*S-1-5-32-555"

if (Test-Path $inf) {
    $content = Get-Content $inf
    if ($content -match 'SeRemoteInteractiveLogonRight') {
        # Le droit est deja defini : on remplace la ligne par la notre.
        $content = $content -replace 'SeRemoteInteractiveLogonRight\s*=.*', $rightLine
    }
    elseif ($content -match '\[Privilege Rights\]') {
        # Section presente mais droit absent : on insere sous l'en-tete.
        $content = $content -replace '(\[Privilege Rights\])', "`$1`r`n$rightLine"
    }
    else {
        # Pas de section : on l'ajoute a la fin.
        $content += "[Privilege Rights]"
        $content += $rightLine
    }
    Set-Content -Path $inf -Value $content -Encoding Unicode
    Write-Host "Droit RDP accorde a 'Remote Desktop Users' dans la Default Domain Controllers Policy." -ForegroundColor Green

    # Incremente la version (partie ordinateur = 16 bits de poids faible) : AD + GPT.ini
    $gpo = Get-GPO -Guid $DDCP
    $obj = Get-ADObject -Identity $gpo.Path -Properties versionNumber
    $ver = [int]$obj.versionNumber
    $new = ($ver -band 0xFFFF0000) -bor ((($ver -band 0xFFFF) + 1) -band 0xFFFF)
    Set-ADObject -Identity $gpo.Path -Replace @{ versionNumber = $new }
    $gptIni = "\\$Domain\SYSVOL\$Domain\Policies\$DDCP\GPT.ini"
    (Get-Content $gptIni) -replace 'Version=\d+', "Version=$new" | Set-Content $gptIni
}
else {
    Write-Host "Introuvable : $inf (Default Domain Controllers Policy manquante ?)" -ForegroundColor Red
}

# --- 3) Appliquer immediatement ---------------------------------------------
gpupdate /target:computer /force | Out-Null
Write-Host "Politique appliquee (gpupdate)." -ForegroundColor Green

# --- VERIFICATION : le droit effectif sur le DC ---
Write-Host "`n[VERIFICATION] Titulaires du droit 'Allow log on through Remote Desktop Services' :" -ForegroundColor Cyan
$tmp = "$env:TEMP\secpol_check.cfg"
secedit /export /areas USER_RIGHTS /cfg $tmp /quiet
(Get-Content $tmp | Select-String 'SeRemoteInteractiveLogonRight')
Remove-Item $tmp -ErrorAction SilentlyContinue
Write-Host "Les users de test peuvent maintenant se connecter en RDP au DC (mot de passe : $TestUserPassword)." -ForegroundColor Magenta
