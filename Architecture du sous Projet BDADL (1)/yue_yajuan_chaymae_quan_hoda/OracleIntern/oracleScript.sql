####sqlplus ZHAOBZ2021@ORCL/ZHAOBZ202101

#SELECT * FROM dba_tablespaces;
DROP TABLESPACE ts_catalogue INCLUDING CONTENTS AND DATAFILES;
 
create tablespace ts_marketing  
logging  
datafile '/u01/app/oracle/oradata/cdb/orcl/ts_marketing.dbf'
size 10m   
extent management local;

# Execution du script contenant les tables, les indexes, les contraintes, ...


#drop table marketing cascade constraint;


#catalogueId,marque,nom,puissance,longueur,nbPlaces,nbPortes,couleur,occasion,prix
/*create table Catalogue(
	catalogueId NUMBER(5) constraint pk_Catalogue_CatalogueId  primary key,
	marque varchar2(50) NOT NULL,
	nom varchar2(500) NOT NULL,
	puissance NUMBER(4) NOT NULL,
	longueur varchar2(500) NOT NULL,
	nbPlaces NUMBER(4) NOT NULL,
	nbPortes NUMBER(4) NOT NULL,
	couleur varchar2(50) NOT NULL,
	occasion varchar2(50) NOT NULL,
	prix NUMBER(8) NOT NULL 
);*/


create table Marketing(
	marketingId NUMBER(5) constraint pk_Marketing_MarketingId  primary key,
	age NUMBER(4) NOT NULL CONSTRAINT chk_Marketing_age CHECK ( AGE between 18 AND 74),
	sexe varchar2(50) NOT NULL CONSTRAINT chk_Marketing_sexe CHECK ( SEXE in ('F','M')),
	taux NUMBER(4) NOT NULL,
	situationFamiliale varchar2(50) NOT NULL,
	nbEnfantsAcharge NUMBER(4) NOT NULL,
	deuxiemeVoiture varchar2(50) NOT NULL
);

select* from all_tables where TABLESPACE_NAME='ts_marketig';

---importer les donnees via dans fichier sqlloader.sql
disconnect;

sqlldr userid = ZHAOBZ2021@ORCL/ZHAOBZ202101 control=/home/ZHAO/Projet/Data/load_Marketing.ctl
--sqlldr userid = ZHAOBZ2021@ORCL/ZHAOBZ202101 control=/home/ZHAO/Projet/Data/load_Catalogue.ctl

select*from Marketing;
