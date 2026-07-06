


1/ GPOS USERS




1.1/ GPO pour empecher l'accès au shell pour worker et secretary. 



gpmc.msc  (win + r)

clic droit sur Group Policy Objects (Objets de stratégie de groupe) > New


edit : 


pour CMD : User Configuration > Policies > Administrative Templates > System > Double-clique sur Prevent access to the command prompt -> Mets sur Enabled.

Registre : Au même endroit -> Double-clique sur Prevent access to registry editing tools -> Mets sur Enabled.


glisser la GPO dans workspace


(sinon c'est qu'un template de gpo, ainsi elle s'applique a un truc, elle devient lié  a une OU, ici workspace est l OU avec tout les type  d user)





reclique dessus


dans security filtering


remove auth user et add les groupe que veux






1.2/ Supprimer et bloquer l'accès à Windows Update (Côté Utilisateur)


c'est l'admin qui doit gérer ça et avoir la vision totale de la chose




User Configuration > Policies > Administrative Templates > Windows Components > Windows Update.



1.3/ ShortCut






User Configuration (Configuration utilisateur) > Preferences > Windows Settings > Shortcuts (Raccourcis).

Fais un clic droit dans la zone vide à droite > New > Shortcut.

Configure la fenêtre comme ceci :

    Action : Update

    Name : Certification Microsoft Security

    Target Type : URL

    Location : All Users Desktop (Pour qu'il se place directement sur le Bureau)

    Target URL : Tu peux mettre un lien générique (ex: [https://learn.microsoft.com](https://learn.microsoft.com))









============================



2/ AUDIT (COMPUTER)






2.1/ GPO SIEM sur les fichiers 


nouvelle GPO


edit

Computer Configuration > Policies > Windows Settings > Security Settings > Advanced Audit Policy Configuration > Audit Policies > Object Access



Audit File System -> configure , coche succes et failure


glisse dans OU workspace






2.2/   GPO SIEM sur le traçage des processus (








Computer Configuration > Policies > Windows Settings > Security Settings > Advanced Audit Policy Configuration > Audit Policies > Detailed Tracking (Suivi détaillé).

Dans le panneau de droite, double-clique sur Audit Process Creation (Auditer la création de processus).

Coche la case Configure the following audit events et coche Success (Succès).



(Optionnel mais très pro) : Va dans 

retour dans edit => computer =>
Administrative Templates > System > Audit Process Creation et active "Include command line in process creation events". Cela permet au SIEM de voir la commande exacte qui a été tapée par l'utilisateur.





Glisse et lie cette GPO dans l'OU Workspace.









2.3/ GPO SIEM sur les modifications de politiques de sécurité (Policy Change)





Computer Configuration > Policies > Windows Settings > Security Settings > Advanced Audit Policy Configuration > Audit Policies > Policy Change (Modification de stratégie).

Dans le panneau de droite, double-clique sur Audit Audit Policy Change (Auditer la modification de la stratégie d'audit).

Coche la case et sélectionne Success et Failure.

Fais de même pour Audit Authorization Policy Change.




Glisse et lie cette GPO dans l'OU Workspace.






------------------------------------



Some script to activate/deactivate SIEM log type



















------------------------------------





Some script to automatize actions over SIEM log