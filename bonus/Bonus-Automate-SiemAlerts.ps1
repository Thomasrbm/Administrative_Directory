# siem/Bonus-Automate-SiemAlerts.ps1

# Inclusion du script Helper pour récupérer la fonction de Pop-up
. "$PSScriptRoot\Bonus-Helper.ps1"

# Définition des ID critiques de tes GPOs Bonus et obligatoires 
# (4663 = Fichier, 4688 = Processus, 4719 = Politique, 4625 = Echec Logon)
$CriticalIDs = @(4663, 4688, 4719, 4625)

# Cherche les alertes dans les 5 dernières minutes
$StartTime = (Get-Date).AddMinutes(-5)
$Events = Get-WinEvent -FilterHashtable @{LogName='Security'; Id=$CriticalIDs; StartTime=$StartTime} -ErrorAction SilentlyContinue

if ($Events) {
    # On prend le dernier événement critique trouvé
    $LatestEvent = $Events[0]
    $EventID = $LatestEvent.Id
    $Time = $LatestEvent.TimeCreated
    
    # Action 1 : Création du rapport automatique sur le Bureau
    $Rapport = "$home\Desktop\ALERTE_SIEM.txt"
    "--- INCIDENT SIEM DETECTE ---" | Out-File $Rapport
    "Date : $Time" | Out-File $Rapport -Append
    "ID de l'événement : $EventID" | Out-File $Rapport -Append
    "Message : $($LatestEvent.Message.Substring(0, 150))..." | Out-File $Rapport -Append
    
    # Action 2 : Afficher une alerte graphique via la fonction du Helper (Icon 16 = Erreur/Croix rouge)
    $MessageAlerte = "ATTENTION : Activité suspecte détectée (Event ID: $EventID) !`nUn rapport détaillé a été généré sur votre Bureau."
    Show-Popup -Message $MessageAlerte -Title "ALERTE CRITIQUE SIEM" -Icon 16
    
} else {
    # Si tout va bien, petit message de confirmation via la fonction du Helper (Icon 64 = Info)
    Show-Popup -Message "Scan terminé. Aucun incident critique récent détecté." -Title "SIEM Monitoring" -Icon 64
}