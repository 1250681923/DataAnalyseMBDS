options(skip=1,BINDSIZE=20971520, ROWS=10000, READSIZE=20971520, ERRORS=999999999)
LOAD DATA 
INFILE '/home/ZHAO/Projet/Data/Marketing.csv'
TRUNCATE
INTO TABLE marketing
FIELDS TERMINATED BY ','
(marketingId,
age ,
sexe ,
taux ,
situationFamiliale ,
nbEnfantsAcharge ,
deuxiemeVoiture)

