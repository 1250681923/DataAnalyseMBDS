##charger tous les libraries possible utilises
install.packages("RJDBC")
library(RJDBC)
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



#-------------------------#
# PREPARATION DES DONNEES #
#-------------------------#


drv <- RJDBC::JDBC(driverClass = "oracle.jdbc.OracleDriver", classPath =  Sys.glob("C:/Users/12506/OneDrive/Desktop/ESTIA 3A/R/Oracle/drivers/*"))

##classPath : add path to drivers jdbc

#Connexion OK
conn <- dbConnect(drv, "jdbc:oracle:thin:@(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=144.21.67.201)(PORT=1521))(CONNECT_DATA=(SERVICE_NAME=pdbest21.631174089.oraclecloud.internal)))", "ZHANG2B20", "ZHANG2B2001")

allTables <- dbGetQuery(conn, "SELECT owner, table_name FROM all_tables where owner = 'ZHANG2B20'")

tableCatalogue <- dbGetQuery(conn, "select * from Catalogue")
tableClients <- dbGetQuery(conn, "select * from Clients")
tableIm <- dbGetQuery(conn, "select * from IMMATRICULATION")
tableMar <- dbGetQuery(conn, "select * from MARKETING")
View(tableCatalogue)
View(tableClients)
View(tableIm)
View(tableMar)


tableIm_f <- merge(tableIm, tableCatalogue, by = c("MARQUE","NOM", "PUISSANCE", "LONGUEUR", "NBPORTES","COULEUR","OCCASION","PRIX"))

summary(tableIm_f)


########################################################################
#-------------------------#
# Petit essai             #
#-------------------------#


tableImEssai <- tableIm_f[c(9, 12)]

View(tableImEssai)

tableEssaiFinal <- merge(tableClients, tableImEssai, by = "IMMATRICULATION", incomparables = NA)
View(tableEssaiFinal)

## supprimer column "IMMATRICULATION"
tableEssaiFinal <- subset(tableEssaiFinal, select=-IMMATRICULATION)
View(tableEssaiFinal)

##ID statistique
table(tableEssaiFinal$CATALOGUEID)

# Creation des ensembles d'apprentissage et de test
id_EA <- tableEssaiFinal[1:7388,]
id_ET <- tableEssaiFinal[7389:11082,]

# Apprentissage du classifeur de type arbre de decision rpart
treeEssai1 <- rpart(CATALOGUEID~., id_EA)
prp(treeEssai1, type=4, extra=1, box.col=c("tomato", "skyblue")[treeEssai1$frame$yval])
##Warning message:
##labs do not fit even at cex 0.15, there may be some overplotting

# Test du classifieur : classe predite
pred.treeEssai1 <- predict(treeEssai1, id_ET, type="class")
##Invalid prediction for "rpart" object

# Apprentissage du classifeur de type arbre de decision C5.0
id_EA$CATALOGUEID <- as.factor(id_EA$CATALOGUEID)
treeEssai2 <- C5.0(CATALOGUEID~., id_EA)
print(treeEssai2)
##Non-standard options: attempt to group attributes
plot(treeEssai2, type="simple")
pred.treeEssai2 <- predict(treeEssai2, id_ET, type="class")
table(pred.treeEssai2)
table(id_ET$CATALOGUEID, pred.treeEssai2)
##La matrice de confusion
tabletreeEssai2 <- as.data.frame(table(id_ET$CATALOGUEID, pred.treeEssai2))
##taux de reussir
colnames(tabletreeEssai2) = list("Classe", "Prediction", "Effectif")
sum(tabletreeEssai2[tabletreeEssai2$Classe==tabletreeEssai2$Prediction,"Effectif"])/nrow(id_ET)
##Error in Ops.factor(tabletreeEssai2$Classe, tabletreeEssai2$Prediction) : 
##level sets of factors are different


#######################################################################
#------------------------------------#
# Le mod¨¨le de la pr¨¦diction du PRIX#
#-----------------------------------#

#fusion des donnees
tableImPrix <- tableIm_f[c(8, 9)]
tablePrixFinal <- merge(tableClients, tableImPrix, by = "IMMATRICULATION", incomparables = NA)
#requ¨ºte pour la distribution des donn¨¦es: Prix
summary(tablePrixFinal$PRIX)
boxplot(tablePrixFinal$PRIX, data=tablePrixFinal, main="Distrubution de Prix", ylab="Prix")

##Changer
table(tableImPrix$PRIX)
##J'ai pas touve une methode qui nous permets de realiser la meme fonction de Update
tableImPrix <- within(tableImPrix,{
  PRIX[PRIX == 3] <- "Luxe"
  PRIX[PRIX == 2] <- "Moyen"
  PRIX[PRIX == 1] <- "Economique"
})

## Visuellement
attach(tablePrixFinal)
tablePrixFinal <- subset(tablePrixFinal, select=-IMMATRICULATION)
qplot(AGE, data=tablePrixFinal, fill=PRIX)
qplot(SEXE, data=tablePrixFinal, fill=PRIX)
qplot(TAUX, data=tablePrixFinal, fill=PRIX)

table(SEXE,PRIX)

qplot(Age, TAUX, data=tablePrixFinal,color=PRIX)

### comparer arbre de decision
Prix_EA <- tablePrixFinal[1:7388,]
Prix_ET <- tablePrixFinal[7389:11082,]


## Aprendissage
#rpart 
str(Prix_EA)
Prix_EA$TAUX <- as.integer(Prix_EA$TAUX)
Prix_ET$TAUX <- as.integer(Prix_ET$TAUX)
str(Prix_EA)

Prixtree1 <- rpart(PRIX~., Prix_EA)
prp(Prixtree1, type=4, extra=1, box.col=c("tomato", "skyblue")[Prixtree1$frame$yval])

#C5.0
Prix_EA$PRIX <- as.factor(Prix_EA$PRIX)
Prixtree2 <- C5.0(PRIX~., Prix_EA)
plot(Prixtree2, type="simple")

#Classification and regression trees
Prixtree3 <- tree(PRIX~., data=Prix_EA)
plot(Prixtree3)
text(Prixtree3, pretty=0)

#comparaison
predPrix.tree1 <- predict(Prixtree1, Prix_ET, type="class")
predPrix.tree2 <- predict(Prixtree2, Prix_ET, type="class")
predPrix.tree3 <- predict(Prixtree3, Prix_ET, type="class")
# Calcul des matrices de confusion
table(Prix_ET$PRIX, predPrix.tree1)
table(Prix_ET$PRIX, predPrix.tree2)
table(Prix_ET$PRIX, predPrix.tree3)


#----------------#
# RANDOM FORESTS #
#----------------#

# Apprentissage du classifeur de type foret aleatoire
rfPrix <- randomForest(PRIX~., Prix_EA)
# Test du classifieur : classe predite
rf_classPrix <- predict(rfPrix,Prix_ET, type="response")
# Matrice de confusion
table(Prix_ET$PRIX, rf_classPrix)

# Test du classifieur : probabilites pour chaque prediction
rf_probPrix <- predict(rfPrix, Prix_ET, type="prob")
# L'objet genere est une matrice 
rf_probPrix


#-------------------------#
# SUPPORT VECTOR MACHINES #
#-------------------------#
# Apprentissage du classifeur de type svm
svmPrix <- svm(PRIX~., Prix_EA, probability=TRUE)
# Test du classifieur : classe predite
svm_classPrix <- predict(svmPrix, Prix_ET, type="response")
# Matrice de confusion
table(Prix_ET$PRIX, svm_classPrix)
# Test du classifieur : probabilites pour chaque prediction
svm_prob <- predict(svmPrix, Prix_ET, probability=TRUE)
# L'objet genere est de type specifique aux svm
svm_prob
# Recuperation des probabilites associees aux predictions
svm_prob <- attr(svm_prob, "probabilities")
# Conversion en un data frame 
svm_prob <- as.data.frame(svm_prob)


#-------------#
# NAIVE BAYES #
#-------------#
# Apprentissage du classifeur de type naive bayes
nbPrix <- naive_bayes(PRIX~., Prix_EA)
nbPrix
# Test du classifieur : classe predite
nbPrix_class <- predict(nbPrix, Prix_ET, type="class")
nbPrix_class
table(nbPrix_class)
# Matrice de confusion
table( Prix_ET$PRIX, nbPrix_class)
# Test du classifieur : probabilites pour chaque prediction
nbPrix_prob <- predict(nbPrix, Prix_ET, type="prob")
# L'objet genere est une matrice
nbPrix_prob

#-----------------#
# NEURAL NETWORKS #
#-----------------#
# Apprentissage du classifeur de type perceptron monocouche
nnPrix <- nnet(PRIX~., Prix_EA, size=12)
nnPrix
# Test du classifieur : classe predite
nnPrix_class <- predict(nnPrix, Prix_ET, type="class")
nnPrix_class
table(nnPrix_class)
# Matrice de confusion
table(Prix_ET$PRIX, nnPrix_class)
# Test du classifieur : probabilites pour chaque prediction
nnPrix_prob <- predict(nnPrix, Prix_ET, type="raw")
# L'objet genere est un vecteur des probabilites de prediction
nnPrix_prob

#---------------------#
# K-NEAREST NEIGHBORS #
#---------------------#
# Apprentissage et test simultanes du classifeur de type k-nearest neighbors
knnPrix <- kknn(PRIX~., Prix_EA, Prix_ET)
# Resultat : classe predite et probabilites de chaque classe pour chaque instance de test
summary(knnPrix)
# Matrice de confusion
table(Prix_ET$PRIX, knnPrix$fitted.values)
# Conversion des probabilites en data frame
knnPrix_prob <- as.data.frame(knnPrix$prob)



#----------------------------------------------------#
# APPLICATION DE LA METHODE arbre de decision (C5.0) #
#----------------------------------------------------#
# Visualisation des donnees a predire
View(tableMar) 

#=== C5.0 ===#
class.treeC50 <- predict(Prixtree2, tableMar, probability=TRUE)
# L'objet genere est de type specifique aux svm
class.treeC50 
# Recuperation des probabilites associees aux predictions
prob.treeC50 <- attr(class.treeC50, "probabilities")
# Conversion en un data frame 
prob.treeC50 <- as.data.frame(prob.treeC50)
resultatPrix <- data.frame(tableMar$ID, class.treeC50, prob.treeC50)


#=== ARBRE DE DECISION C5.0  ===#
class.treeC50 <- predict(Prixtree2, tableMar, type="class")
prob.treeC50 <- predict(Prixtree2, tableMar, type="prob")
resultatPrix <- data.frame(tableMar, class.treeC50, prob.treeC50)
resultatPrix <- data.frame(tableMar, class.treeC50)



# Renommage de la colonne des classes predites
names(resultatPrix)[7] <- "PRIX"

#---------------------------------#
# ENREGISTREMENT DES PREDICTIONS  #
#---------------------------------#
# Enregistrement du fichier de resultats au format csv
write.table(resultat1, file='predictions.csv', sep="\t", dec=".", row.names = F)






#####################################################################################



#----------------------------------------#
# Le mod¨¨le de la pr¨¦diction du OCCASION#
#--------------------------------------#

#----------------------------------------#
# Preparation de donnees                #
#--------------------------------------#

tableImOCCA <- tableIm_f[c(7, 9)]
tableOCCAFinal <- merge(tableClients, tableImOCCA, by = "IMMATRICULATION", incomparables = NA)
#requ¨ºte pour la distribution des donn¨¦es: OCCASION
summary(tableOCCAFinal$OCCASION)
##changer les types de donnees
str(tableOCCAFinal)
tableOCCAFinal$TAUX <- as.integer(tableOCCAFinal$TAUX)

#----------------#
# Visuellement   #
#----------------#

##On trouve qu'ils y moins de voitures occasions
library(ggplot2)
qplot(OCCASION, data=tableOCCAFinal)
table(tableOCCAFinal$DEUXIEMEVOITURE,tableOCCAFinal$OCCASION)
qplot(DEUXIEMEVOITURE, data=tableOCCAFinal, color=OCCASION)
qplot(TAUX, data=tableOCCAFinal, fill=OCCASION, bins =5)
boxplot(AGE~OCCASION, data=tableOCCAFinal, col=c("red","blue"))
qplot(SEXE, data=tableOCCAFinal, color=OCCASION)

#----------------#
# Aprendissage #
#----------------#
tableOCCAFinal <- subset(tableOCCAFinal, select=-IMMATRICULATION)
OCCA_EA <- tableOCCAFinal[1:7388,]
OCCA_ET <- tableOCCAFinal[7389:11082,]

#3 arbres de decision 
OCCAtree1 <- rpart(OCCASION~., OCCA_EA)
OCCA_EA$OCCASION <- as.factor(OCCA_EA$OCCASION)
OCCAtree2 <- C5.0(OCCASION~., OCCA_EA)
OCCAtree3 <- tree(OCCASION~., data=OCCA_EA)
#RANDOM FORESTS
rfOCCA <- randomForest(OCCASION~., OCCA_EA)
# SUPPORT VECTOR MACHINES
svmOCCA <- svm(OCCASION~., OCCA_EA, probability=TRUE)
# NAIVE BAYES
nbOCCA <- naive_bayes(OCCASION~., OCCA_EA)
# NEURAL NETWORKS
nnOCCA <- nnet(OCCASION~., OCCA_EA, size=12)
# K-NEAREST NEIGHBORS
knnOCCA <- kknn(OCCASION~., OCCA_EA, OCCA_ET)


#--------------------------------------------------#
# ##Text des classifieurs et matrice de confusion  #
#--------------------------------------------------#

##Text des arbres et matrice de confusion 
predOCCA.tree1 <- predict(OCCAtree1, OCCA_ET, type="class")
predOCCA.tree2 <- predict(OCCAtree2, OCCA_ET, type="class")
predOCCA.tree3 <- predict(OCCAtree3, OCCA_ET, type="class")
# Calcul des matrices de confusion
table(OCCA_ET$OCCASION, predOCCA.tree1)
table(OCCA_ET$OCCASION, predOCCA.tree2)
table(OCCA_ET$OCCASION, predOCCA.tree3)
####
#       FALSE TRUE
#FALSE  3189   37
#TRUE    290  178
##Text des classifieurs et matrice de confusion
result.rfOCCA <- predict(rfOCCA,OCCA_ET, type="response")
table(OCCA_ET$OCCASION, result.rfOCCA)
#####result.rfOCCA
########FALSE TRUE
#FALSE  3181   45
#TRUE    290  178
result.svmOCCA <- predict(svmOCCA,OCCA_ET, type="response")
table(OCCA_ET$OCCASION, result.svmOCCA)
####result.svmOCCA
########FALSE TRUE
#FALSE  3186   40
#TRUE    307  161
result.treeNaiveOCCA <- predict(nbOCCA,OCCA_ET, type="class")
table(OCCA_ET$OCCASION, result.treeNaiveOCCA)
#####result.treeNaiveOCCA
#########FALSE TRUE
##FALSE  2518  708
#TRUE      2  466
result.treeNnetOCCA <- predict(nnOCCA, OCCA_ET,type="class")
table(OCCA_ET$OCCASION, result.treeNnetOCCA)
#####result.treeNnetOCCA
########FALSE
#FALSE  3226
#TRUE    468
table(OCCA_ET$OCCASION, knnOCCA$fitted.values)
#####FALSE TRUE
#FALSE  3020  206
#TRUE    228  240


#-----------------------#
# CALCUL DE COURBES ROC #
#-----------------------#

# Test du classifieur : probabilites pour chaque prediction
p.treeRpartOCCA <- predict(OCCAtree1, OCCA_ET, type="prob")
# Courbe ROC
roc.predOCCA1 <- prediction(p.treeRpartOCCA[,2], OCCA_ET$OCCASION)
roc.perfOCCA1 <- performance(roc.predOCCA1,"tpr","fpr")

p.treec50OCCA <- predict(OCCAtree2, OCCA_ET, type="prob")
# Courbe ROC
roc.predOCCA2 <- prediction(p.treec50OCCA[,2], OCCA_ET$OCCASION)
roc.perfOCCA2 <- performance(roc.predOCCA2,"tpr","fpr")

p.treeTreeOCCA <- predict(OCCAtree3, OCCA_ET, type="vector")
# Courbe ROC
roc.predOCCA3 <- prediction(p.treeTreeOCCA[,2], OCCA_ET$OCCASION)
roc.perfOCCA3 <- performance(roc.predOCCA3,"tpr","fpr")

rf_probOCCA <- predict(rfOCCA, OCCA_ET, type="prob")
# Courbe ROC
roc.predOCCA4 <- prediction(rf_probOCCA[,2], OCCA_ET$OCCASION)
roc_perfOCCA4 <- performance(roc.predOCCA4,"tpr","fpr")

svm_probOCCA <- predict(svmOCCA, OCCA_ET, probability=TRUE)
# Recuperation des probabilites associees aux predictions
svm_probOCCA <- attr(svm_probOCCA, "probabilities")
# Conversion en un data frame 
svm_probOCCA <- as.data.frame(svm_probOCCA)
# Courbe ROC sur le meme graphique
roc.predOCCA5 <- prediction(svm_probOCCA[,2], OCCA_ET$OCCASION)
roc.perfOCCA5 <- performance(roc.predOCCA5,"tpr","fpr")

nb_probOCCA <- predict(nbOCCA, OCCA_ET, type="prob")
# Courbe ROC
roc.predOCCA6 <- prediction(nb_probOCCA[,2], OCCA_ET$OCCASION)
roc.perfOCCA6 <- performance(roc.predOCCA6,"tpr","fpr")

nn_probOCCA <- predict(nnOCCA, OCCA_ET, type="raw")
# Courbe ROC
roc.predOCCA7 <- prediction(nn_probOCCA[,1], OCCA_ET$OCCASION)
roc.perfOCCA7 <- performance(roc.predOCCA7,"tpr","fpr")

# Conversion des probabilites en data frame
knn_probOCCA <- as.data.frame(knnOCCA$prob)
# Courbe ROC
roc.predOCCA8 <- prediction(knn_probOCCA[,2], OCCA_ET$OCCASION)
roc.perfOCCA8 <- performance(roc.predOCCA8,"tpr","fpr")

#------------------------#
# CALCUL DE L INDICE AUC #
#------------------------#
auc.treeOCCA1 <- performance(roc.predOCCA1, "auc")
auc.treeOCCA2 <- performance(roc.predOCCA2, "auc")
auc.treeOCCA3 <- performance(roc.predOCCA3, "auc")
auc.treeOCCA4 <- performance(roc.predOCCA4, "auc")
auc.treeOCCA5 <- performance(roc.predOCCA5, "auc")
auc.treeOCCA6 <- performance(roc.predOCCA6, "auc")
auc.treeOCCA7 <- performance(roc.predOCCA7, "auc")
auc.treeOCCA8 <- performance(roc.predOCCA8, "auc")


attr(auc.treeOCCA1, "y.values")
# [[1]]
# [1] 0.9241559
attr(auc.treeOCCA2, "y.values")
# [[1]]
# [1] 0.9241559
attr(auc.treeOCCA3, "y.values")
# [[1]]
# [1] 0.9241559
attr(auc.treeOCCA4, "y.values")
# [[1]]
# [1] 0.9247706
attr(auc.treeOCCA5, "y.values")
# [[1]]
# [1] 0.9208312
attr(auc.treeOCCA6, "y.values")
# [[1]]
# [1] 0.9246225
attr(auc.treeOCCA7, "y.values")
# [[1]]
# [1] 0.5
attr(auc.treeOCCA8, "y.values")
# [[1]]
# [1] 0.9033746



#------------------------#
# plot                   #
#------------------------#

##arbres de decisions
prp(OCCAtree1, type=4, extra=1, box.col=c("tomato", "skyblue")[OCCAtree1$frame$yval])
plot(OCCAtree2, type="simple")
plot(OCCAtree3)
text(OCCAtree3, pretty=0)


# Courbe ROC
plot(roc.perfOCCA1, col = "green")
plot(roc.perfOCCA2, col = "red", add=TRUE)
plot(roc.perfOCCA3, col = "blue", add=TRUE)
plot(roc_perfOCCA4, add = TRUE, col = "magenta")
plot(roc.perfOCCA5, add = TRUE, col = "darkorange")
plot(roc.perfOCCA6, add = TRUE, col = "darkgreen")
plot(roc.perfOCCA7, add = TRUE, col = "black")
plot(roc.perfOCCA8, add = TRUE, col = "darkmagenta")



#----------------------------------------------------#
# APPLICATION DE LA METHODE RANDOM FORESTS           #
#----------------------------------------------------#
# Visualisation des donnees a predire
View(tableMar) 

#=== RANDOM FORESTS ===#
class.treerfOCCA <- predict(rfOCCA, tableMar, probability=TRUE)
resultatOCCA <- data.frame(tableMar, class.treerfOCCA)

# Renommage de la colonne des classes predites
names(resultatOCCA)[7] <- "OCCASION"
