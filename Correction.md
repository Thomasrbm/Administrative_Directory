



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


"Worker", "Direction", "Secretary", "Administrator" | ForEach-Object {
    Write-Host "`n--- Membres du groupe : $_ ---" -ForegroundColor Cyan
    Get-ADGroupMember -Identity $_ | Format-Table Name, SamAccountName
}



=====================

GPO : 


gpresult /h report.html


gpresult /r



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