


GPO : 


gpresult /h report.html


gpresult /r



gpmc.msc





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