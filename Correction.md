



OU : 





dsa.msc


sinon, 


Server Manager > Tools > usres >






prouver : 


Get-ADOrganizationalUnit -Filter * | Format-Table Name, DistinguishedName



======================



lister les groups 



Get-ADGroup -Filter * | Format-Table Name, GroupCategory, DistinguishedName


Get-ADGroup -Filter "Name -eq 'Worker' -or Name -eq 'Direction' -or Name -eq 'Secretary' -or Name -eq 'Administrator'" | Format-Table Name, DistinguishedName





users : 


dsa.msc



Get-ADGroupeMember Secretary
Get-ADGroupeMember Direction
Get-ADGroupeMember Worker
Get-ADGroupeMember Admistrator



=====================

GPO : 




gpresult /s PC-WORKER-01 /user domolia\worker1 /r
gpresult /s PC-WORKER-01 /user domolia\admin1 /r
gpresult /s PC-WORKER-01 /user domolia\secretary1 /r
gpresult /s PC-WORKER-01 /user domolia\direction1 /r



gpmc.msc





montrer dans le \\domolia.local  le fond ecran + les .msi







=================================


LES DISQUES : 

explorateurs de fichier + :


Get-PSDrive -PSProvider FileSystem


Get-Acl -Path "D:\WorkPlan" | Format-List










=================================


AUDIT : 



auditpol /get /category:*




gpmc.msc



Configuration ordinateur > Stratégies > Paramètres Windows > Paramètres de sécurité > Stratégies locales > Stratégie d'audit.



voir les success et failure 




eventvwr.msc



lancer les scripts de proff