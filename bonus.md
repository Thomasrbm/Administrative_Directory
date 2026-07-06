


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






1.2/




1.3/



============================



2/ AUDIT (COMPUTER)






2.1/ GPO SIEM sur les fichiers 


nouvelle GPO


edit

Computer Configuration > Policies > Windows Settings > Security Settings > Advanced Audit Policy Configuration > Audit Policies > Object Access



Audit File System -> configure , coche succes et failure


glisse dans OU workspace




2.1/



2.2/



2.3/




------------------------------------



