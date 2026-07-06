# Inclusion du script Helper
. "$PSScriptRoot\Bonus-Helper.ps1"

# Appel de la fonction graphique
$Selection = Show-SiemCheckboxMenu -Title "SIEM - Désactivation" -LabelText "Cochez les logs à DÉSACTIVER :" -ButtonText "Désactiver"

if ($null -ne $Selection) {
    $List = ""
    
    if ($Selection.FileSys) { Set-SiemAudit "File System" "disable"; $List += "- Accès Fichiers`n" }
    if ($Selection.Process) { Set-SiemAudit "Process Creation" "disable"; $List += "- Processus`n" }
    if ($Selection.Policy)  { Set-SiemAudit "Audit Policy Change" "disable"; $List += "- Politiques`n" }
    
    if ($List -ne "") { Show-Popup "Les logs suivants ont été DÉSACTIVÉS :`n`n$List" "Succès" 48 }
    else { Show-Popup "Aucune case n'a été cochée." "Information" 64 }
} else {
    Show-Popup "Opération annulée par l'utilisateur." "Annulé" 48
}