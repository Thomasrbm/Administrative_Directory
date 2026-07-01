# =============================================================
# reset.ps1
# Description : Remet la machine a un etat PRE-AD propre, pour pouvoir
#               relancer le deploiement sans recreer la VM.
#               Idempotent et adaptatif : detecte l'etat de la machine et
#               fait l'etape suivante. Comme demoter / quitter le domaine
#               REDEMARRE la VM, il faut RELANCER ce script apres chaque
#               reboot jusqu'au message "Deja propre".
#
#               Etapes enchainees (selon l'etat) :
#                 DC            -> supprime users/groupes/dossiers crees, puis demote
#                 Serveur membre-> quitte le domaine (workgroup)
#                 Standalone    -> desinstalle les roles AD DS + DNS
#
#               ORDRE entre les 2 serveurs : lancer d'abord sur le WORKER
#               (DC additionnel), puis sur SRV-ADMIN (dernier DC = detruit
#               la foret).
# =============================================================
. "$PSScriptRoot\helpers.ps1"
Test-Admin

# Nettoyage des dossiers/partages/CSV crees (toujours tente, sans erreur si absent)
foreach ($s in "AdminFiles", "GenericFiles", "WorkshopFiles") { Remove-SmbShare -Name $s -Force -ErrorAction SilentlyContinue }
foreach ($p in "C:\AdminFiles", "C:\GenericFiles", "C:\WorkshopFiles") { Remove-Item $p -Recurse -Force -ErrorAction SilentlyContinue }
Remove-Item "C:\test_db.csv", "C:\AD_Backup.csv", "C:\AD_Backup_groups.csv", "C:\test_resultats.txt" -Force -ErrorAction SilentlyContinue

# DomainRole : 0/1 workgroup, 2 standalone server, 3 serveur membre, 4/5 = DC
$role = (Get-CimInstance Win32_ComputerSystem).DomainRole

if ($role -ge 4) {
    # ===== C'est un controleur de domaine : nettoyer les objets AD puis demoter =====
    Write-Host "Etat : CONTROLEUR DE DOMAINE -> nettoyage des objets + demotion." -ForegroundColor Cyan

    # Supprime les comptes et groupes crees par les scripts / tester (best effort)
    foreach ($u in "user.admin", "user.worker", "test.user") {
        Remove-ADUser -Identity $u -Confirm:$false -ErrorAction SilentlyContinue
    }
    foreach ($g in "TestGroup", "TestGroup2", "TestDistri", "IT", "IT-Copie", "Distribution-IT") {
        Remove-ADGroup -Identity $g -Confirm:$false -ErrorAction SilentlyContinue
    }
    Write-Host "Objets AD crees supprimes." -ForegroundColor Green

    # Dernier DC du domaine ? (si oui -> on detruit la foret)
    $dcCount = @(Get-ADDomainController -Filter *).Count
    Write-Host "Demotion en cours (un mot de passe admin LOCAL va etre demande). Reboot a la fin." -ForegroundColor Yellow

    if ($dcCount -le 1) {
        # Dernier DC : detruit le domaine / la foret
        Uninstall-ADDSDomainController -LastDomainControllerInDomain -RemoveApplicationPartitions -Force
    } else {
        # DC additionnel (worker) : demotion gracieuse, se nettoie sur l'autre DC
        Uninstall-ADDSDomainController -Force
    }
    # -> la machine redemarre toute seule ; RELANCER reset.ps1 apres le reboot
}
elseif ($role -eq 3) {
    # ===== Serveur membre (deja demote mais encore dans le domaine) : sortir du domaine =====
    Write-Host "Etat : SERVEUR MEMBRE -> sortie du domaine (workgroup). Reboot a la fin." -ForegroundColor Cyan
    $cred = Get-Credential -Message "Admin du domaine pour quitter proprement (ou Annuler pour forcer)"
    if ($cred) {
        Remove-Computer -UnjoinDomainCredential $cred -WorkgroupName "WORKGROUP" -Force -Restart
    } else {
        Remove-Computer -WorkgroupName "WORKGROUP" -Force -Restart
    }
    # -> reboot ; RELANCER reset.ps1 apres
}
else {
    # ===== Standalone : desinstaller les roles AD DS + DNS s'ils sont presents =====
    if ((Get-WindowsFeature AD-Domain-Services).Installed) {
        Write-Host "Etat : STANDALONE -> desinstallation des roles AD DS / DNS. Reboot a la fin." -ForegroundColor Cyan
        Uninstall-WindowsFeature AD-Domain-Services, DNS -IncludeManagementTools -Restart
    } else {
        Write-Host "Deja propre : pas de role AD DS, machine a un etat pre-AD. Rien a faire." -ForegroundColor Green
    }
}
