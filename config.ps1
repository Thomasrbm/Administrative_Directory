# =============================================================
# config.ps1
# Description : Topologie du sujet "Administrative Directory" en UN SEUL endroit.
#               Domaine, OU, groupes, disques, dossiers, et surtout la MATRICE
#               de permissions (qui a le droit de faire quoi sur quel dossier).
#               A inclure avec : . "$PSScriptRoot\config.ps1"   (adapter le chemin)
#
# Note : dot-source => les variables ci-dessous atterrissent dans le scope appelant.
# =============================================================

# --- Domaine (aligne sur Automatic_Directory : domolia.local) ---
$Domain    = "domolia.local"
$NetBIOS   = "DOMOLIA"
$DomainDN  = "DC=domolia,DC=local"

# --- Organizational Units demandees (III.1) ---
$OU_Workspace      = "OU=Workspace,$DomainDN"
$OU_Administration = "OU=Administration,$DomainDN"

# --- Groupes demandes (III.1) ---
# Ordre : du moins privilegie au plus privilegie
$Groups = @("Worker", "Direction", "Secretary", "Administrator")

# --- Utilisateurs de TEST (pour demontrer GPO + permissions) ---
# 1 user par groupe, place dans la bonne OU et ajoute a son groupe.
# 'OpenOffice = $true' => ajoute aussi au groupe OpenOfficeUsers (demo du
# deploiement "a la demande"). Mot de passe commun = convention du lab.
$TestUserPassword = "TotalyN0tSecure"
$TestUsers = @(
    @{ Name = "worker1";    OU = $OU_Workspace;      Group = "Worker";        OpenOffice = $true  }
    @{ Name = "direction1"; OU = $OU_Workspace;      Group = "Direction";     OpenOffice = $false }
    @{ Name = "secretary1"; OU = $OU_Workspace;      Group = "Secretary";     OpenOffice = $false }
    @{ Name = "admin1";     OU = $OU_Administration; Group = "Administrator"; OpenOffice = $false }
)

# --- Disques + dossiers demandes (III.1) ---
# Chaque dossier est partage en SMB (necessaire pour l'acces reseau + drive maps).
$Folders = @(
    @{ Path = "D:\WorkPlan";        Share = "WorkPlan" }
    @{ Path = "D:\Management";      Share = "Management" }
    @{ Path = "E:\HumanResources";  Share = "HumanResources" }
    @{ Path = "E:\Estimate";        Share = "Estimate" }
    @{ Path = "E:\Client";          Share = "Client" }
)

# Les deux disques a acceder par TOUS les groupes (drive maps auto) : III.2
$Disks = @("D:", "E:")

# =============================================================
# MATRICE DE PERMISSIONS  (III.2)
# =============================================================
# Le sujet donne 4 listes : Access / Edit / Create / Delete par groupe.
# On les fusionne en un niveau NTFS effectif par (groupe, dossier) :
#
#   "Read"          -> Access seul (lecture/liste)                 = ReadAndExecute
#   "WriteNoDelete" -> Access + Edit + Create mais PAS Delete      = ReadAndExecute + Write
#   "Modify"        -> Access + Edit + Create + Delete             = Modify (droit complet)
#   (absent)        -> aucun droit
#
# Cas particulier releve dans le sujet : Worker peut editer/creer dans WorkPlan
# mais "Delete : Nothing" => WorkPlan = WriteNoDelete (et non Modify).
# Les incoherences du sujet (ex: Direction "edit" Management sans etre dans "access")
# sont resolues par l'union : qui peut ecrire peut forcement lire.
$PermissionMatrix = @{
    "Worker" = @{
        "D:\WorkPlan"       = "WriteNoDelete"   # access + edit + create, pas de delete
        "D:\Management"     = "Read"            # access seul
        "E:\HumanResources" = "Read"            # access seul
    }
    "Direction" = @{
        "D:\WorkPlan"       = "Modify"
        "D:\Management"     = "Modify"
        "E:\HumanResources" = "Modify"
        "E:\Estimate"       = "Modify"
        "E:\Client"         = "Modify"
    }
    "Secretary" = @{
        "D:\Management"     = "Modify"
        "E:\HumanResources" = "Modify"
        "E:\Estimate"       = "Modify"
        "E:\Client"         = "Modify"
    }
    "Administrator" = @{
        "D:\WorkPlan"       = "Modify"
        "D:\Management"     = "Modify"
        "E:\HumanResources" = "Modify"
        "E:\Estimate"       = "Modify"
        "E:\Client"         = "Modify"
    }
}
