# Inclusion du script Helper (Le point indique qu'on charge les fonctions dans ce script)
. "$PSScriptRoot\Bonus-Helper.ps1"

# Appel de la fonction graphique personnalisée
$Selection = Show-SiemCheckboxMenu -Title "SIEM - Activation" -LabelText "Cochez les logs à ACTIVER :" -ButtonText "Activer"

if ($null -ne $Selection) {
    $List = ""
    
    # Utilisation de la fonction Set-SiemAudit
    if ($Selection.FileSys) { Set-SiemAudit "File System" "enable"; $List += "- Accès Fichiers`n" }
    if ($Selection.Process) { Set-SiemAudit "Process Creation" "enable"; $List += "- Processus`n" }
    if ($Selection.Policy)  { Set-SiemAudit "Audit Policy Change" "enable"; $List += "- Politiques`n" }
    
    # Utilisation de la fonction Show-Popup
    if ($List -ne "") { Show-Popup "Les logs suivants ont été ACTIVÉS :`n`n$List" "Succès" 64 }
    else { Show-Popup "Aucune case n'a été cochée." "Information" 64 }
} else {
    Show-Popup "Opération annulée par l'utilisateur." "Annulé" 48
}