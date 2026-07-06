# Définition des types de logs SIEM disponibles
$Options = @(
    [pscustomobject]@{ Categorie = "1. Accès aux Fichiers (Bonus 2.1)"; Subcategory = "File System" }
    [pscustomobject]@{ Categorie = "2. Création de Processus (Bonus 2.2)"; Subcategory = "Process Creation" }
    [pscustomobject]@{ Categorie = "3. Modification de Politique (Bonus 2.3)"; Subcategory = "Audit Policy Change" }
)

# Affiche la fenêtre de sélection Windows (GUI)
$Selection = $Options | Out-GridView -Title "SIEM : Sélectionnez les logs à DÉSACTIVER (Ctrl+Clic pour plusieurs)" -PassThru

if ($Selection) {
    $DeactivatedList = ""
    foreach ($Item in $Selection) {
        # Désactivation via auditpol
        auditpol /set /subcategory:$($Item.Subcategory) /success:disable /failure:disable | Out-Null
        $DeactivatedList += "- $($Item.Categorie)`n"
    }
    
    # Pop-up de confirmation
    $wshell = New-Object -ComObject Wscript.Shell
    $wshell.Popup("Les logs suivants ont été DÉSACTIVÉS :`n`n$DeactivatedList", 0, "SIEM - Désactivation", 48)
} else {
    $wshell = New-Object -ComObject Wscript.Shell
    $wshell.Popup("Opération annulée. Aucun log n'a été désactivé.", 0, "SIEM - Annulation", 48)
}