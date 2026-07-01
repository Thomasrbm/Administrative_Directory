# LoadDataBase.ps1 - Charge une base de donnees depuis un fichier CSV
# Parametres : Path, Delimiter

. "$PSScriptRoot\helpers.ps1"

Test-Admin

$Path      = Get-Input "Chemin du fichier CSV a charger" "Chemin" "C:\AD_Backup.csv"

if (-not (Test-Path $Path)) { Write-Host "Fichier introuvable." -ForegroundColor Red; exit }


$Delimiter = Get-Input "Delimiteur CSV" "Delimiteur" ";"
# mdp par defaut pour tous les comptes importes, saisi via un pop-up masque
$Password  = Get-PasswordInput "Mot de passe par defaut pour les utilisateurs importes" "Mot de passe par defaut"


Import-Csv -Path $Path -Delimiter $Delimiter | ForEach-Object {
    # on capture le SamAccountName dans une variable locale (plus fiable dans -Filter)
    $sam = $_.SamAccountName
    # si l'utilisateur existe deja, on ne le recree pas
    if (Get-ADUser -Filter "SamAccountName -eq '$sam'" -ErrorAction SilentlyContinue) {
        Write-Host "$sam existe deja, ignore." -ForegroundColor Yellow
    } else {
        # Splatting : parametres regroupes dans un hashtable pour la lisibilite
        $UserParams = @{
            Name                  = $sam   # -Name est OBLIGATOIRE pour New-ADUser (CN de l'objet)
            SamAccountName        = $sam
            GivenName             = $_.GivenName
            Surname               = $_.Surname
            EmailAddress          = $_.EmailAddress
            AccountPassword       = $Password
            Enabled               = $true
            ChangePasswordAtLogon = $true
        }
        New-ADUser @UserParams
        Write-Host "$sam cree." -ForegroundColor Green
    }
}

# --- Rechargement des GROUPES depuis le fichier *_groups.csv genere par SaveDataBase ---
# (corrige l'asymetrie : SaveDataBase exporte les groupes, LoadDataBase les recree)
$GroupsPath = $Path -replace "\.csv", "_groups.csv"
if (Test-Path $GroupsPath) {
    Write-Host "`n[GROUPES] Rechargement depuis $GroupsPath" -ForegroundColor Cyan
    Import-Csv -Path $GroupsPath -Delimiter $Delimiter | ForEach-Object {
        $gname = $_.Name
        if (Get-ADGroup -Filter "Name -eq '$gname'" -ErrorAction SilentlyContinue) {
            Write-Host "$gname existe deja, ignore." -ForegroundColor Yellow
        } else {
            # valeurs par defaut si une colonne est vide dans le CSV
            $scope = if ($_.GroupScope)    { $_.GroupScope }    else { "Global" }
            $cat   = if ($_.GroupCategory) { $_.GroupCategory } else { "Security" }
            New-ADGroup -Name $gname -GroupScope $scope -GroupCategory $cat -Description $_.Description
            Write-Host "$gname cree." -ForegroundColor Green
        }
    }
}



# --- VERIFICATION : combien de comptes du CSV sont effectivement presents dans AD ? ---
Write-Host "`n[VERIFICATION] Comptes du CSV presents dans AD :" -ForegroundColor Cyan
$total = 0; $ok = 0
Import-Csv -Path $Path -Delimiter $Delimiter | ForEach-Object {
    $total++
    # ajoute que ceux dans ok si present.
    if (Get-ADUser -Filter { SamAccountName -eq $_.SamAccountName } -ErrorAction SilentlyContinue) { $ok++ }
}


Write-Host "$ok / $total comptes du fichier sont presents dans AD." -ForegroundColor Green
