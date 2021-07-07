/*
Source Hadoop HDFS
Création des tables externes HIVE pointant vers des fichiers physiques
HADOOP puis des tables externes Oracle SQL pointant vers les tables 
externes HIVE correspondante


Créer par étape sur la base DWH la table externe pointant vers 
le fichier HDFS suivant :(Immatriculations.csv).
étape 1 : creation de fichiers dans Hadoop hdfs, 
étape 2: creation de tables externes dans la base Hive 
étape 3: creation de la table externe dans la la base DWH (SQL), 
étape 4: accès aux données de la table externe dans la la base DWH
*/

-- étape 1 : creation du fichier Immatriculations.csv dans Hadoop hdfs
--IMMATRICULATION_HDFS_EXT (IMMID STRING, IMM STRING, MARQUE STRING,  NOM STRING, PUISSANCE INT, LONGUEUR STRING, NBPLACES INT, NBPORTES INT,COULEUR STRING, OCCASION STRING, PRIX INT )

-- 1.1 création d'une directorie hadoop
$ hdfs dfs -mkdir /immatriculation_ZHANG_LUO
$ hdfs dfs -mkdir /catalogue_FAZAZIIDRISSI_AITBAALI



-- 1.2 ajout du  fichier dans hdfs
-- structure du fichier Immatriculations.csv
-- IMMID , IMM , MARQUE ,  NOM , PUISSANCE, LONGUEUR, NBPLACES, NBPORTES,COULEUR, OCCASION, PRIX 

-- ajout du fichier 
$ hdfs dfs -put /home/ZHANG/data/Immatriculations.csv /immatriculation_ZHANG_LUO
$ hdfs dfs -put /home/FAZAZIIDRISSI/Data/Catalogue.csv /catalogue_FAZAZIIDRISSI_AITBAALI
-- 1.3 vérification de l'ajout.
$ hdfs dfs -ls /immatriculation_ZHANG_LUO
$ hdfs dfs -ls /catalogue_FAZAZIIDRISSI_AITBAALI

--Etape 2 : Création de la table externe HIVE pointant vers le fichier HDFS

-- IMMATRICULATION_HDFS_EXT (IMM STRING, MARQUE STRING,  NOM STRING, PUISSANCE INT, LONGUEUR STRING, NBPLACES INT, NBPORTES INT,COULEUR STRING, OCCASION STRING, PRIX INT )

-- Etape 2.1 lancer Hive

[oracle@bigdatalite ~]$ beeline
Beeline version 1.1.0-cdh5.4.0 by Apache Hive

beeline>   

-- Etape2.2 Se connecter à HIVE

beeline>   !connect jdbc:hive2://localhost:10000

Enter username for jdbc:hive2://localhost:10000: oracle
Enter password for jdbc:hive2://localhost:10000: ********
(password : welcome1)

-- Etape2.3 Créer la table externe HIVE pointant vers le fichier recommandation_ext.txt

-- table externe Hive 
drop EXTERNAL table IMMA_ZHANG_LUO_HDFS_H_EXT;

CREATE EXTERNAL TABLE  IMMA_ZHANG_LUO_HDFS_H_EXT  (
IMMATRICULATION STRING, MARQUE STRING,  NOM STRING, PUISSANCE STRING, LONGUEUR STRING, NBPLACES STRING, NBPORTES STRING, COULEUR STRING, OCCASION STRING, PRIX STRING)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' 
STORED AS TEXTFILE LOCATION 'hdfs:/immatriculation_ZHANG_LUO'
TBLPROPERTIES ('skip.header.line.count' = '1');

drop EXTERNAL table CATA_FAZAZIIDRISSI_AITBAALI_HDFS_H_EXT;

CREATE EXTERNAL TABLE  CATA_FAZAZIIDRISSI_AITBAALI_HDFS_H_EXT  (
CATALOGUEID INT, MARQUE STRING,  NOM STRING, PUISSANCE STRING, LONGUEUR STRING, NBPLACES STRING, NBPORTES STRING, COULEUR STRING, OCCASION STRING, PRIX STRING)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' 
STORED AS TEXTFILE LOCATION 'hdfs:/catalogue_FAZAZIIDRISSI_AITBAALI'
TBLPROPERTIES ('skip.header.line.count' = '1');

--ici qui montre: No rows affected (0.151 seconds) 
-- c'est normale

-- 2.4 vérifications
-- vérifier la présence des lignes et de la table
select * from IMMA_ZHANG_LUO_HDFS_H_EXT;
select * from CATA_FAZAZIIDRISSI_AITBAALI_HDFS_H_EXT;
--270 rows selected (0.44 seconds)


-- Etape 3. Créer la table externe Oracle SQl IMMA_ZHANG_LUO_HDFS_H_EXT pointant vers la table
-- externe HIVE équivalentes 

$ sqlplus myOracleLogin@myDB/myOracleLoginPassword;
$ sqlplus ZHAOBZ2021@ORCL/ZHAOBZ202101;

-- table externe Oracle SQL pointant vers la table externe HIVE
drop table IMMA_ZHANG_LUO_HDFS_H_EXT;

CREATE TABLE  IMMA_ZHANG_LUO_HDFS_H_EXT(
IMMATRICULATION varchar2(12), 
MARQUE varchar2(12), 
NOM varchar2(12), 
PUISSANCE number(8), 
LONGUEUR varchar2(12), 
NBPLACES number(3), 
NBPORTES number(3),
COULEUR varchar2(12), 
OCCASION varchar2(12), 
PRIX number(8)
)
ORGANIZATION EXTERNAL (
TYPE ORACLE_HIVE 
DEFAULT DIRECTORY   ORACLE_BIGDATA_CONFIG
ACCESS PARAMETERS 
(
com.oracle.bigdata.tablename=default.IMMA_ZHANG_LUO_HDFS_H_EXT
)
) 
REJECT LIMIT UNLIMITED;

drop table CATA_HDFS_H_EXT;
--ORA-00972: identifier is too long: CATA_FAZAZIIDRISSI_AITBAALI_HDFS_H_EXT

CREATE TABLE  CATA_HDFS_H_EXT(
CATALOGUEID varchar2(12), 
MARQUE varchar2(12), 
NOM varchar2(12), 
PUISSANCE number(8), 
LONGUEUR varchar2(12), 
NBPLACES number(3), 
NBPORTES number(3),
COULEUR varchar2(12), 
OCCASION varchar2(12), 
PRIX number(8)
)
ORGANIZATION EXTERNAL (
TYPE ORACLE_HIVE 
DEFAULT DIRECTORY   ORACLE_BIGDATA_CONFIG
ACCESS PARAMETERS 
(
com.oracle.bigdata.tablename=default.CATA_FAZAZIIDRISSI_AITBAALI_HDFS_H_EXT
)
) 
REJECT LIMIT UNLIMITED;

-- 3.4. Consultation de tables externes Oracle SQL 
--  compter les lignes
select count(*) from IMMA_ZHANG_LUO_HDFS_H_EXT;
select count(*) from CATA_HDFS_H_EXT;

  COUNT(*)
----------
       271


-- consultation de la table APPRECIATIONS_yourLogin_MIAGE_ONS_EXT 
-- Se limiter aux N premières lignes
select * from IMMA_ZHANG_LUO_HDFS_H_EXT where rownum <10;

