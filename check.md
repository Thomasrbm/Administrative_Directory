


Verifir via GUI



1 user par groupe 

worker1
direction1
secretary1
admin1



mdp : TotalyN0tSecure







======  OU

win + r  : dsa.msc

dans domolia.local  on voit les Organizational unit Admin et workspacer


======= Groups




====== Disks


======= Folders 








==================================================  GPO


gpmc.msc



===== slack et Openoffice




deplier foret => domains => domolia.local (deplier aussi)

GROUP poloci object : on voit les gpo




dans security filtering on voit : 

- open office = open officer user => doit etre join
- Slack = tous les user auth






======== Desktop


  \\domolia.local\SYSVOL\domolia.local\


  dans les gpo =>  dans settings 

  ==> en bas dans user config on voit le chemin




=======   LES FICHIER   D:  ET    E:


worker : peut creer mais pas nommer (car nommer donne droit delete)
peut modif que Workplane et y cree file etc


direction : bug sujet impossible doit pas avoir acces a D:MANAGEMENT
mais pouvoir le modifier, ducoup on donne acces


secretary : pas acces a workplan

Admin : peut tout faire aussi








==================================== NETWORK EVENT LOGING


auditpol /get /category:*
donne la politique d audit = la ou on ecrit dans le journal de securite si y a un event



le journal  de securite :  eventvwr.msc
 

 windows log -> security (mpntrera pas le user reel mais le pc)




dans .\listUserEvents


• Computer Account Management Activity

machine reelle


• Distribution Group Management Activity


group de msg


• Security Group Management Activity

groupe de seu





• User Account Management Activity

compte worker1 etc





• Directory Service Access Activity


si on accede a un dir ou pas.



• Logoff Activitu

• Logon Activity




==================================== looging script 


juste exec les scripts