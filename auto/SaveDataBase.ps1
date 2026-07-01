# SaveDataBase.ps1 - Sauvegarde les utilisateurs et groupes AD en CSV
# Parametres : Path, Delimiter, proprietes supplementaires (optionnel)

. "$PSScriptRoot\helpers.ps1"

Test-Admin


$Path      = Get-Input "Chemin du fichier CSV de sortie" "Chemin" "C:\AD_Backup.csv"
$Delimiter = Get-Input "Delimiteur CSV" "Delimiteur" ";"
$Extra     = Get-OptionalInput "Proprietes supplementaires separees par des virgules (optionnel)" "Proprietes"
$Props     = @("SamAccountName","GivenName","Surname","EmailAddress","Enabled","DistinguishedName")

if ($Extra) { $Props += (Get-PropsList $Extra) }

# Splatting : options communes a Export-Csv regroupees
$CsvOptions = @{ Delimiter = $Delimiter; NoTypeInformation = $true; Encoding = "UTF8" }

# Export des utilisateurs
Get-ADUser -Filter * -Properties $Props |
    Select-Object $Props |
    Export-Csv -Path $Path @CsvOptions

# Export des groupes (fichier separe *_groups.csv)
$GroupProps = "Name", "GroupScope", "GroupCategory", "Description"
Get-ADGroup -Filter * -Properties $GroupProps |
    Select-Object $GroupProps |
    Export-Csv -Path ($Path -replace "\.csv", "_groups.csv") @CsvOptions

Write-Host "Sauvegarde terminee : $Path" -ForegroundColor Green

# --- VERIFICATION : les fichiers existent-ils et combien de lignes contiennent-ils ? ---
Write-Host "`n[VERIFICATION] Fichiers CSV generes :" -ForegroundColor Cyan
$GroupsPath = $Path -replace "\.csv", "_groups.csv"


# test les fichier existent
foreach ($f in @($Path, $GroupsPath)) {
    if (Test-Path $f) {
        $count = (Import-Csv -Path $f -Delimiter $Delimiter | Measure-Object).Count
        Write-Host "OK : $f ($count lignes)" -ForegroundColor Green
    } else {
        Write-Host "MANQUANT : $f" -ForegroundColor Red
    }
}
