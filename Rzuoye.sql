drop table clients;

select * from clients where DEUXIEMEVOITURE is not null;
select * from clients where DEUXIEMEVOITURE = 'TRUE' or DEUXIEMEVOITURE= 'FALSE';
select * from clients where DEUXIEMEVOITURE != 'TRUE' and DEUXIEMEVOITURE != 'FALSE';

//¿ªÊ¼

--Pourque Age soit dans [18, 84]
select * from clients where age < 18 or age > 84;
DELETE from clients where age < 18 or age > 84;

--Domain de valeurs 'SEXE': 'F','M'
select * from clients where SEXE != 'M' and SEXE != 'F';
delete from clients where SEXE != 'M' and SEXE != 'F';

--Domain de valeurs 'taux': [544, 74185]
select * from clients where taux = ' ';
delete from clients where taux = ' ';
select * from clients where taux = '?';
delete from clients where taux = '?';
select * from clients where taux < 544 or taux > 74185;
delete from clients where TO_NUMBER(taux) < 544 or TO_NUMBER(taux) > 74185;

--Pour SITUATIONFAMILIALE, on fait group by pour voir les erreurs possibles
select sum(age),SITUATIONFAMILIALE from clients group by SITUATIONFAMILIALE;
delete from clients where SITUATIONFAMILIALE = '?';
delete from clients where SITUATIONFAMILIALE = ' ';
delete from clients where SITUATIONFAMILIALE = 'N/D';

--Domain de valeurs NBENFANTSACHARGE: [0, 4]
select * from clients where NBENFANTSACHARGE < 0 or NBENFANTSACHARGE > 4;
delete from clients where NBENFANTSACHARGE < 0 or NBENFANTSACHARGE > 4;

--DEUXIEMEVOITURE: TRUE or FALSE
select * from clients where DEUXIEMEVOITURE != 'TRUE' and DEUXIEMEVOITURE != 'FALSE';
delete from clients where DEUXIEMEVOITURE != 'TRUE' and DEUXIEMEVOITURE != 'FALSE';

-- on touche rien pour les valuers IMMATRICULATION car il y a pas d'errers comme ' ', '?', 'N/D'



--IMMATRICULATION

--Afin d'utiliser Group by, on doit nettoyer au moins un column, par example 'PRIX'
--Domain de valeurs PRIX: [7500, 101300]
select * from IMMATRICULATION where prix < 7500 or prix > 101300;
--on touche pas si'l y a pas d'erreurs

--Pour les valeurs marque:
select sum(prix), MARQUE from IMMATRICULATION group by MARQUE;
--on touche pas si'l y a pas d'erreurs

--Pour les valeurs nom:
select sum(prix), nom from IMMATRICULATION group by nom;
--on touche pas si'l y a pas d'erreurs

--Domain de valeurs PUISSANCE: [55, 507]
select * from IMMATRICULATION where PUISSANCE < 55 or PUISSANCE > 507;
--on touche pas si'l y a pas d'erreurs

--Pour les valeurs longueur:
select sum(prix), longueur from IMMATRICULATION group by longueur;
--on touche pas si'l y a pas d'erreurs

--Domain de valeurs NBPLACES: [5, 7]
select * from IMMATRICULATION where NBPLACES < 5 or NBPLACES > 7;
--on touche pas si'l y a pas d'erreurs

--Domain de valeurs NBPORTES: [3, 5]
select * from IMMATRICULATION where NBPORTES < 3 or NBPORTES > 5;
--on touche pas si'l y a pas d'erreurs

--Pour les valeurs COULEUR:
select sum(prix), COULEUR from IMMATRICULATION group by COULEUR;
--on touche pas si'l y a pas d'erreurs

--Pour les valeurs OCCASION:
select sum(prix), OCCASION from IMMATRICULATION group by OCCASION;
--on touche pas si'l y a pas d'erreurs



--MARKETING
--Domain de valeurs 'taux': [544, 74185]
select * from MARKETING where taux < 544 or taux > 74185;
delete from MARKETING where taux < 544 or taux > 74185;
commit;