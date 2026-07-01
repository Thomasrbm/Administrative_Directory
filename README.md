# Administrative Directory — GPO & SIEM

## Récupérer les scripts sur la VM

```powershell
Invoke-WebRequest -Uri "https://github.com/Thomasrbm/Administrative_Directory/archive/main.zip" -OutFile "C:\scripts.zip"
Expand-Archive -Path "C:\scripts.zip" -DestinationPath "C:\" -Force
```

Puis : `cd C:\Administrative_Directory-main` et `Set-ExecutionPolicy Unrestricted -Force`.

---

Suite du projet **Automatic_Directory**. On repart de la forêt `domolia.local`
(un seul DC : **SRV-ADMIN**) et on ajoute les GPO, les permissions et l'audit
(« SIEM ») demandés par le sujet.

> Tous les scripts se lancent **en administrateur sur SRV-ADMIN**, sans argument :
> ils posent leurs questions via des pop-ups et affichent une **[VERIFICATION]**
> à la fin. Autoriser l'exécution une fois par session : `Set-ExecutionPolicy Unrestricted -Force`.

## Arborescence

```
auto/    Scripts d'Automatic_Directory (mise en place des serveurs / foret)
prep/    III.1  OU, groupes, disques D:/E:, dossiers
gpo/     III.2  GPO (wallpaper, drive maps, Slack, OpenOffice) + permissions NTFS
siem/    III.3/III.4  audit + scripts de lecture des journaux
config.ps1   Topologie + MATRICE de permissions (à lire en premier)
helpers.ps1  Fonctions communes (popups, ACL, SACL, GPO)
```

## Ordre d'exécution

**0. Serveur** (si la forêt n'existe pas encore) — dossier `auto/`, cf. son `Readme`
(`main_admin.ps1` → reboot → `main_admin_post.ps1`).

**1. Préparation** (`prep/main_prep.ps1`)
OU `Workspace`/`Administration` → groupes `Worker/Direction/Secretary/Administrator`
→ disques `D:`/`E:` → dossiers + partages SMB.
Prérequis : **2 disques virtuels ajoutés à la VM** (pour D: et E:).

**2. GPO + permissions** (`gpo/main_gpo.ps1`)
Wallpaper → Drive Maps (S:/T:) → Slack (obligatoire) → OpenOffice (optionnel, filtré
par groupe `OpenOfficeUsers`) → **matrice NTFS** (`05_FolderPermissions.ps1`).
Pour Slack/OpenOffice : déposer les MSI dans un partage (ex: `SYSVOL\installers\`).

**3. SIEM** (`siem/main_siem.ps1`)
Active l'audit des 7 activités + l'audit des dossiers (SACL).
Ensuite, à la demande : `ListConnectedBetween`, `ListUserEvents`,
`IsolateFolderAccess`, `ListUserIPs`, `ListSecurityIncidents`.

## Ce qui est une « vraie » GPO vs. autre chose

| Item du sujet | Mécanisme réel |
|---|---|
| Fond d'écran | GPO registre (User Config) |
| Slack / OpenOffice | GPO **script de logon** (déploiement MSI) |
| Accès + connexion aux disques | GPO **Drive Maps** (Group Policy Preference) |
| Accès / édition / création / suppression dossiers | **ACL NTFS** (pas une GPO au sens registre) |
| Audit « SIEM » | `auditpol` (sous-catégories) + **SACL** sur les dossiers |

## Matrice de permissions (résumé)

| Groupe | D:\WorkPlan | D:\Management | E:\HumanResources | E:\Estimate | E:\Client |
|---|---|---|---|---|---|
| Worker | Lire+Créer/Éditer (pas suppr.) | Lecture | Lecture | — | — |
| Direction | Modify | Modify | Modify | Modify | Modify |
| Secretary | — | Modify | Modify | Modify | Modify |
| Administrator | Modify | Modify | Modify | Modify | Modify |

Détail (et niveaux `Read` / `WriteNoDelete` / `Modify`) : voir `config.ps1`.

## EventID utiles (SIEM)

| Activité | EventID |
|---|---|
| Computer Account Mgmt | 4741 / 4742 / 4743 |
| Security Group Mgmt | 4727 / 4728 / 4729 / 4731 |
| Distribution Group Mgmt | 4744 / 4749 / 4750 |
| User Account Mgmt | 4720 / 4722 / 4725 / 4726 |
| Directory Service Access | 4662 |
| Logon / Logoff | 4624 (échec 4625) / 4634 / 4647 |
| Accès dossier (SACL) | 4663 |
