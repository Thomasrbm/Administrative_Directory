# Définition des types de logs SIEM disponibles
$Options = @(
    [pscustomobject]@{ Categorie = "1. Accès aux Fichiers (Bonus 2.1)"; Subcategory = "File System" }
    [pscustomobject]@{ Categorie = "2. Création de Processus (Bonus 2.2)"; Subcategory = "Process Creation" }
    [pscustomobject]@{ Categorie = "3. Modification de Politique (Bonus 2.3)"; Subcategory = "Audit Policy Change" }
)

# Affiche la fenêtre de sélection Windows (GUI)
$Selection = $Options | Out-GridView -Title "SIEM : Sélectionnez les logs à ACTIVER (Ctrl+Clic pour plusieurs)" -PassThru

if ($Selection) {
    $ActivatedList = ""
    foreach ($Item in $Selection) {
        # Activation via auditpol
        auditpol /set /subcategory:$($Item.Subcategory) /success:enable /failure:enable | Out-Null
        $ActivatedList += "- $($Item.Categorie)`n"
    }
    
    # Pop-up de confirmation
    $wshell = New-Object -ComObject Wscript.Shell
    $wshell.Popup("Les logs suivants ont été ACTIVÉS :`n`n$ActivatedList", 0, "SIEM - Activation", 64)
} else {
    $wshell = New-Object -ComObject Wscript.Shell
    $wshell.Popup("Opération annulée. Aucun log n'a été activé.", 0, "SIEM - Annulation", 48)
}