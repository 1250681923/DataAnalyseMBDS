/*

Créer par étape sur la base DWH les tables externes pointant vers 
les tables oracle Nosql suivantes : client.

Etape 1 : création de tables sous oracle nosql
<voir le programme java ConcessionnaireBase.java>

Etape 2 : Création de la table externe HIVE pour une table oracle NoSQL

CLIENT_ONS_H_EXT (CLIENTID Int, AGE Int, SEXE STRING, TAUX Int, SITUATIONFAMILIALE STRING, NBENFANTSACHARGE Int, DEUXIEMEVOITURE STRING, IMMATRICULATION STRING );

Etape 3: Création de la table externe Oracle Sql pour une table externe Hive
CONCESSION_CLIENT_ONS_EXT

Etape 4: Consultation de la table externe Oracle SQL 

*/




-- 2.1 lancer Hive

[oracle@bigdatalite ~]$ beeline
Beeline version 1.1.0-cdh5.4.0 by Apache Hive

beeline>   

-- 2.2 Se connecter à HIVE

beeline>   !connect jdbc:hive2://localhost:10000

Enter username for jdbc:hive2://localhost:10000: oracle
Enter password for jdbc:hive2://localhost:10000: ********
(password : welcome1)

-- 2.3 Créer les tables externes HIVE pointant vers les tables
-- équivalentes oracle Nosql

-- table externe Hive CLIENT_ONS_H_EXT
drop table CLIENT_ONS_H_EXT;


CREATE EXTERNAL TABLE  CLIENT_ONS_H_EXT (CLIENTID Int, AGE STRING, SEXE STRING, TAUX STRING, SITUATIONFAMILIALE STRING, NBENFANTSACHARGE STRING, DEUXIEMEVOITURE STRING, IMMATRICULATION STRING )
STORED BY 'oracle.kv.hadoop.hive.table.TableStorageHandler'
TBLPROPERTIES (
"oracle.kv.kvstore" = "kvstore",
"oracle.kv.hosts" = "bigdatalite.localdomain:5000", 
"oracle.kv.hadoop.hosts" = "bigdatalite.localdomain/127.0.0.1", 
"oracle.kv.tableName" = "CLIENTS_ORACLE_ZHAO");
--virifier
describe extended CLIENT_ONS_H_EXT;
select * from CLIENT_ONS_H_EXT;

-- 3. Créer les tables externes Oracle SQl pointant vers les tables
-- externes HIVE qui elles mêmes pointent vers la table équivalente 
-- oracle Nosql
-- si vous voyez le message suivant :
-- connected to a iddle instance
-- faites startup
>sqlplus / as sysdba
sql> show pdbs
 CON_ID CON_NAME                       OPEN MODE  RESTRICTED
---------- ------------------------------ ---------- ----------
         2 PDB$SEED                       READ ONLY  NO
         4 ORCL                          READ WRITE NO
-- 3.1 Démarrer la base Oracle SQL CDH si elle ne l'est pas déjà
-- ourvrir un xterm
$ sqlplus ZHAOBZ2021@ORCL/ZHAOBZ202101 


-- 3.2 Créer les deux directories suivantes : ORACLE_BIGDATA_CONFIG et 
-- ORA_BIGDATA_CL_bigdatalite. 
-- La directorie ORACLE_BIGDATA_CONFIG sert à stocker les lignes
-- rappatriées des bases distantes.
-- Opération à faire une seule fois.

SQL> create or replace directory ORACLE_BIGDATA_CONFIG as '/u01/bigdatasql_config';
SQL> create or replace directory "ORA_BIGDATA_CL_bigdatalite" as '';

-- vérification
SQL> select DIRECTORY_NAME from dba_directories;


-- 3.4 Créer la table externe Oracle CONCESSION_CLIENT_ONS_EXT pointant vers la table externe HIVE équivalente.

-- table externe Oracle SQL CONCESSION_CLIENT_ONS_EXT pointant vers la table externe HIVE
drop table CLIENT_ONS_H_O_EXT;

create table CLIENT_ONS_H_O_EXT (
clientId			number(9),
age  				varchar2(5),
sexe				varchar2(10),
taux 				varchar2(8),
situationFamiliale  varchar2(20),
nbEnfantsAcharge	varchar2(5),
DeuxiemeVoiture 	varchar2(5),
immatriculation 	varchar2(10)
)
ORGANIZATION EXTERNAL (
TYPE ORACLE_HIVE 
DEFAULT DIRECTORY   ORACLE_BIGDATA_CONFIG
ACCESS PARAMETERS 
(
com.oracle.bigdata.tablename=default.CLIENT_ONS_H_EXT
)
) 
REJECT LIMIT UNLIMITED;


-- 4. Consultation de la table externe Oracle SQL 
-- 4.1 compter les lignes
select count(*) from CLIENT_ONS_H_O_EXT;

-- 4.2 structure de la tables externes
desc CLIENT_ONS_H_O_EXT;

--4.3 consultation de la tables

-- consultation de la table CLIENT_ONS_H_O_EXT et formatage des colonnes
-- Se limiter aux 10 premières lignes
select * from CLIENT_ONS_H_O_EXT 
where rownum <10;


