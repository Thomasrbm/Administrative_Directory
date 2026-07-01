# =============================================================
# 01_GPO_Wallpaper.ps1 - GPO "Define screen desktop" (III.2)
#   Impose un fond d'ecran (wallpaper) a tous les utilisateurs des deux OU.
#   Vraie GPO basee sur le registre (User Configuration) => 100% scriptable.
# =============================================================
. "$PSScriptRoot\..\helpers.ps1"
. "$PSScriptRoot\..\config.ps1"
Test-Admin
Import-Module GroupPolicy -ErrorAction Stop

$GpoName = "Wallpaper - Fond d'ecran Domolia"
# Chemin de l'image : idealement dans SYSVOL (replique + accessible par tous les clients).
$Wall = Get-Input "Chemin UNC de l'image de fond (mets-la dans SYSVOL de preference)" `
    "Wallpaper" "\\$Domain\SYSVOL\$Domain\wallpaper.jpg"

# Cree la GPO si absente
$gpo = Get-GPO -Name $GpoName -ErrorAction SilentlyContinue
if (-not $gpo) { $gpo = New-GPO -Name $GpoName; Write-Host "GPO creee." -ForegroundColor Green }

# Cle User : ...\Policies\System  ->  Wallpaper + WallpaperStyle
$Key = "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System"
Set-GPRegistryValue -Name $GpoName -Key $Key -ValueName "Wallpaper"      -Type String -Value $Wall | Out-Null
Set-GPRegistryValue -Name $GpoName -Key $Key -ValueName "WallpaperStyle" -Type String -Value "2"   | Out-Null  # 2 = etire

# Lie la GPO aux deux OU (tous les utilisateurs metiers + admins)
foreach ($ou in @($OU_Workspace, $OU_Administration)) {
    New-GPLink -Name $GpoName -Target $ou -LinkEnabled Yes -ErrorAction SilentlyContinue | Out-Null
    Write-Host "GPO liee a $ou" -ForegroundColor Green
}

# --- VERIFICATION ---
Write-Host "`n[VERIFICATION] Valeurs de registre de la GPO :" -ForegroundColor Cyan
Get-GPRegistryValue -Name $GpoName -Key $Key | Select-Object ValueName, Value, Type | Format-Table -AutoSize
Write-Host "Sur un client : gpupdate /force puis re-login pour voir le fond d'ecran." -ForegroundColor Yellow
