



exec : main_admin  => prep => gpo => siem




========================== dl slack et openoffice


avec le script  dans prep le dl


aller dans gpmc.msc 

clique droit slack -> edit

user config -> policier -> software settgins -> 
software install


clique droit   -> new -> package


mette le chemin : \\domolia.local\SYSVOL\domolia.local\installers\Slack.msi




Assigned :  app pousse auto a l user

(published = proposed)

(advanced = ouvre direct la fenetre detaille)





===============================

1. « Define screen desktop »



impose l environnement de bureau : 

- fond d ecran par exempl
-  ecran de veille
- verouiller ou non la personnalisation du bureau



2. « Define OpenOffice program deployment if required by each user »


met a disposition le .msi (Microsoft Installer) 
de open office pour les user qui le veulent


contrairement au .exe qui esst opaque et fait ce qu il veut


le .msi est declaratif et c est le moteur windows installer seulement qui install.




3. « Define Slack non-optional installation for each new user »


install slack pour tout le monde 






4.  acces au fichiers selon les groupes 







================================================


(Considere par le sujet comme SIEM)

Network event logging : 





1. Computer Account Management Activity


tout ce qui touche aux comptes machines :

- ordi rejoint le domaine
- compte machine cree, modif ou suppr
- proprietes qui changent



chaque pc qui rejoint un domain cree automatique une compte machine
mdp aleatoire identifie la machine elle meme 


2. Distribution Group Management Activity



toute modif sur les groupe de distributions

ajout/retrait membre 






3. Security Group Management Activity



meme chose pour group user avec droits








4. User Account Management Activity





pour les comptes user


création, suppression, activation/désactivation, changement ou réinitialisation de mot de passe, déverrouillage, modification des propriétés




5. Directory Service Access Activity




acces aux objet AD : 


objet = entree de la db AD 

en gros c est lacces a un objet precis la db 




6. Logon Activity



les ouverture de session

(detecte les attaque brute force)





7. Logoff Activity



combine avec logon  = donne plage horaire de session








==============================



Logging scripts



- script qui est co entre 2 time 


- script event d un user particulier entre 2 time tag


- script isole log sur un folder




- script list ip used par user


- script list security incident 






==============================
 



 BONUS






