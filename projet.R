install.packages("RJDBC")
library(RJDBC)

drv <- RJDBC::JDBC(driverClass = "oracle.jdbc.OracleDriver", classPath =  Sys.glob("C:/Users/12506/OneDrive/Desktop/ESTIA 3A/R/Oracle/drivers/*"))

##classPath : add path to drivers jdbc

#Connexion OK
conn <- dbConnect(drv, "jdbc:oracle:thin:@(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=144.21.67.201)(PORT=1521))(CONNECT_DATA=(SERVICE_NAME=pdbest21.631174089.oraclecloud.internal)))", "ZHANG2B20", "ZHANG2B2001")

allTables <- dbGetQuery(conn, "SELECT owner, table_name FROM all_tables where owner = 'BABEAU2B20'")

tableCatalogue <- dbGetQuery(conn, "select * from Catalogue")
tableClients <- dbGetQuery(conn, "select * from Clients")
tableIm <- dbGetQuery(conn, "select * from IMMATRICULATION")
tableMar <- dbGetQuery(conn, "select * from MARKETING")
View(tableCatalogue)
View(tableClients)
View(tableIm)
View(tableMar)

##charger tous les libraries possible utilises
library(rvest)
library(ggplot2)
library(dplyr)
library(scales)
library(maps)
library(mapproj)
library(plotly)
library(rpart)
library(rpart.plot)
library(C50)
library(tree)
library(ROCR)
library(randomForest)
library(e1071)
library(naivebayes)
library(nnet)
library(kknn)



tableIm_f <- merge(tableIm, tableCatalogue, by = c("MARQUE","NOM", "PUISSANCE", "LONGUEUR", "NBPORTES","COULEUR","OCCASION","PRIX"))

tableIm_f <- tableIm_f[c(9, 12)]

View(tableIm_f)

tableFinal <- merge(tableClients, tableIm_f, by = "IMMATRICULATION", incomparables = NA)
View(tableFinal)

## supprimer column "IMMATRICULATION"
tableFinal <- subset(tableFinal, select=-IMMATRICULATION)
View(tableFinal)