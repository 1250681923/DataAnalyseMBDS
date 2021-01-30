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
# Le modèle de la prédiction du PRIX#
#-----------------------------------#

#fusion des donnees
tableImPrix <- tableIm_f[c(8, 9)]
tablePrixFinal <- merge(tableClients, tableImPrix, by = "IMMATRICULATION", incomparables = NA)
#requête pour la distribution des données: Prix
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
# Le modèle de la prédiction du OCCASION#
#--------------------------------------#

#----------------------------------------#
# Preparation de donnees                #
#--------------------------------------#

tableImOCCA <- tableIm_f[c(7, 9)]
tableOCCAFinal <- merge(tableClients, tableImOCCA, by = "IMMATRICULATION", incomparables = NA)
#requête pour la distribution des données: OCCASION
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



#####################################################################################

#----------------------------------------#
# Le modèle de la prédiction du NBPORTES#
#--------------------------------------#


#set.seed(1234)
#ind<-sample(2,nrow(tableFinal),replace=TRUE, prob=c(0.7,0.3))
#table_EA <- tableFinal[ind==1,]
#table_ET <- tableFinal[ind==2,]

##NBPORTES
tableImNP<- tableIm_f[c(5,9)]
View(tableImNP)
tableFinal_np<- merge(tableClients, tableImNP,by= "IMMATRICULATION", incomparables =NA)
View(tableFinal_np)

summary(tableFinal_np$NBPORTES)

##Visuellement
tableFinal_np$NBPORTES <- as.factor(tableFinal_np$NBPORTES)
attach(tableFinal_np)
tableFinal_np<-subset(tableFinal_np, select = -IMMATRICULATION)
qplot(NBPORTES, data=tableFinal_np)
qplot(SEXE,data=tableFinal_np, fill=NBPORTES)
qplot(NBENFANTSACHARGE,data=tableFinal_np, fill=NBPORTES)
qplot(TAUX,data=tableFinal_np, fill=NBPORTES, bins=5)
qplot(DEUXIEMEVOITURE, data=tableFinal_np, fill=NBPORTES)
qplot(SITUATIONFAMILIALE, data=tableFinal_np, fill=NBPORTES)
boxplot(AGE~NBPORTES, data=tableFinal_np, col=c("red","blue"))
##Apprentissage en différents classifeurs
NBPORTES_EA <- tableFinal_np[1:7388,]
NBPORTES_ET <- tableFinal_np[7389:11082,]
NBPORTES_EA$TAUX <- as.integer(NBPORTES_EA$TAUX)
NBPORTES_ET$TAUX <- as.integer(NBPORTES_ET$TAUX)
###apprentissages
#-------------#
#decision tree#
#-------------#
####rpart
#NBPORTES_EA$NBPORTES <- as.integer(NBPORTES_EA$NBPORTES)
NBPORTESTree1<-rpart(NBPORTES~., NBPORTES_EA)
prp(NBPORTESTree1,type=4,extra = 1, box.col = c("tomato","skyblue")[NBPORTESTree1$frame$yval])
####C5.0
#NBPORTES_EA$NBPORTES <- as.factor(NBPORTES_EA$NBPORTES)
NBPORTESTree2<-C5.0(NBPORTES~., NBPORTES_EA)
plot(NBPORTESTree2,type="simple")
####Tree
NBPORTESTree3<-tree(NBPORTES~., data=NBPORTES_EA)
text(NBPORTESTree3,pretty = 0)
###comparaison###
predNBPORTES.tree1 <- predict(NBPORTESTree1, NBPORTES_ET, type="vector")
predNBPORTES.tree2 <- predict(NBPORTESTree2, NBPORTES_ET, type="class")
predNBPORTES.tree3 <- predict(NBPORTESTree3, NBPORTES_ET, type="class")
table(NBPORTES_ET$NBPORTES,predNBPORTES.tree1)
table(NBPORTES_ET$NBPORTES,predNBPORTES.tree2)
table(NBPORTES_ET$NBPORTES,predNBPORTES.tree3)
###ROC
#rpart
pNP.tree1<-predict(NBPORTESTree1,NBPORTES_ET,type = "vector")#############尝试使用type = "vector"而不是type = "c" 。 您的变量是逻辑的，因此rpart -function应该已经生成了回归树，而不是分类树。 predict.rpart的文档指出，类型class和prob仅用于分类树
print(pNP.tree1)
rocNP.pred1<-prediction(pNP.tree1,NBPORTES_ET$NBPORTES)##rocNP.pred1<-prediction(pNP.tree1[,2],NBPORTES_ET$NBPORTES)
print(rocNP.pred1)
rocNP.pref1<-performance(rocNP.pred1,"tpr","fpr")
print(rocNP.pref1)
plot(rocNP.pref1,col="green")

#c5.0
pNP.tree2<-predict(NBPORTESTree2,NBPORTES_ET,type = "prob")
rocNP.pred2<-prediction(pNP.tree2[,2],NBPORTES_ET$NBPORTES)
rocNP.pref2<-performance(rocNP.pred2,"tpr","fpr")  
plot(rocNP.pref2,add = TRUE,col="blue")

#tree
pNP.tree3<-predict(NBPORTESTree3,NBPORTES_ET,type = "vector")
rocNP.pred3<-prediction(pNP.tree3[,2],NBPORTES_ET$NBPORTES)
rocNP.pref3<-performance(rocNP.pred3,"tpr","fpr")  
plot(rocNP.pref3,add = TRUE,col="red")

##calcul de l'AUC
aucNP.tree1<-performance(rocNP.pred1,"auc")
attr(aucNP.tree1,"y.values")
aucNP.tree2<-performance(rocNP.pred2,"auc")
attr(aucNP.tree2,"y.values")
aucNP.tree3<-performance(rocNP.pred3,"auc")
attr(aucNP.tree3,"y.values")
#-------------#
#RANDOM FORETS#
#-------------#
rfNP<-randomForest(NBPORTES~., NBPORTES_EA)
rf_classNP<-predict(rfNP,NBPORTES_EA,type = "response")
table(NBPORTES_EA$NBPORTES,rf_classNP)
rf_probNP<-predict(rfNP,NBPORTES_ET, type = "prob" )
rf_probNP

rf_predNP<-prediction(rf_probNP[,2],NBPORTES_ET$NBPORTES)
rf_prefNP<-performance(rf_predNP,"tpr","fpr")
plot(rf_prefNP,add = TRUE, col="yellow")

rf_aucNP<-performance(rf_predNP,"auc")
attr(rf_aucNP,"y.values")
#-----------------------#
#SUPPORT VECTOR MACHINES#
#-----------------------#
svmNP<-svm(NBPORTES~., NBPORTES_EA,probability=TRUE)
svm_classNP<-predict(svmNP,NBPORTES_ET,type = "response")
table(NBPORTES_ET$NBPORTES,svm_classNP)
svm_prob<-predict(svmNP,NBPORTES_ET,probability=TRUE)
svm_prob

svm_prob<-attr(svm_prob,"probabilities")
svm_prob<-as.data.frame(svm_prob)
svm_pred<-prediction(svm_prob[,2],NBPORTES_ET$NBPORTES)##Error in `[.data.frame`(svm_prob, , 2) : undefined columns selected
svm_pref<-performance(rf_predNP,"tpr","fpr")
plot(svm_pref,add = TRUE, col="black")

svm_aucNP<-performance(svm_pred,"auc")
attr(svm_aucNP,"y.values")
#-------------#
#NAIVE BAYES  #
#-------------#
#tableFinal_np$NBPORTES <- as.factor(tableFinal_np$NBPORTES)
nbNP<-naive_bayes(NBPORTES~., NBPORTES_EA)
nbNP
nbNP_class<-predict(nbNP,NBPORTES_ET,type = "class")
nbNP_class
table(nbNP_class)
table(NBPORTES_ET$NBPORTES,nbNP_class)
nbNP_prob<-predict(nbNP,NBPORTES_ET,type="prob")
nbNP_prob
nbNP_pred<-prediction(nbNP_prob[,2],NBPORTES_ET$NBPORTES)
nbNP_pref<-performance(nbNP_pred,"tpr","fpr")
plot(nbNP_pref,add = TRUE, col="purple")
nbNP_aucNP<-performance(nbNP_pred,"auc")
attr(nbNP_aucNP,"y.values")
#-------------------#
#NEURAL NETWORKS    #
#-------------------#
nnNP<-nnet(NBPORTES~., NBPORTES_EA,size=12)
nnNP
nnNP_class<-predict(nnNP,NBPORTES_ET, TYPE="class")
nnNP_class
table(nnNP_class)
table(NBPORTES_ET$NBPORTES,nnNP_class)
nnNP_prob<-predict(nnNP,NBPORTES_ET,type = "raw")
nnNP_prob
nnNP_pred<-prediction(nnNP_prob,NBPORTES_ET$NBPORTES)
nnNP_pref<-performance(nnNP_pred,"tpr","fpr")
plot(nnNP_pref,add = TRUE, col="orange")
nnNP_aucNP<-performance(nnNP_pred,"auc")
attr(nnNP_aucNP,"y.values")
#-------------------#
#K-NEAREST NEIGHBORS#
#-------------------#
knnNP<-kknn(NBPORTES~., NBPORTES_EA,NBPORTES_ET)
summary(knnNP)
table(NBPORTES_ET$NBPORTES,knnNP$fitted.values)
knnNP_prob<-as.data.frame(knnNP$prob)
knnNP_pred<-prediction(knnNP_prob[,2],NBPORTES_ET$NBPORTES)
knnNP_pref<-performance(knnNP_pred,"tpr","fpr")
plot(nnNP_pref,add = TRUE, col="black")
knnNP_aucNP<-performance(knnNP_pred,"auc")
attr(knnNP_aucNP,"y.values")

#----------------------------------------------------#
# APPLICATION DE LA METHODE NAIVE BAYES                   #
#----------------------------------------------------#
# Visualisation des donnees a predire
View(tableMar) 

#=== NAIVE BAYES ===#
class.treerpartNB <- predict(nbNP, tableMar, probability=TRUE)
resultatNB <- data.frame(tableMar, class.treerpartNB)

# Renommage de la colonne des classes predites
names(resultatNB)[7] <- "NBPORTES"
























#############################################################################################
#####################################################################################



#----------------------------------------#
# Le modèle de la prédiction du LONGUEUR#
#--------------------------------------#

#----------------------------------------#
# Preparation de donnees                #
#--------------------------------------#

tableImLG <- tableIm_f[c(4, 9)]
tableLGFinal <- merge(tableClients, tableImLG, by = "IMMATRICULATION", incomparables = NA)
#requête pour la distribution des données: LONGUEUR
summary(tableLGFinal$LONGUEUR)
##changer les types de donnees
str(tableLGFinal)
tableLGFinal$TAUX <- as.integer(tableLGFinal$TAUX)
tableLGFinal <- subset(tableLGFinal, select=-IMMATRICULATION)

#----------------#
# Visuellement   #
#----------------#

##On trouve qu'ils y moins de voitures moyenne
library(ggplot2)
qplot(LONGUEUR, data=tableLGFinal)
table(tableLGFinal$DEUXIEMEVOITURE,tableLGFinal$LONGUEUR)
qplot(DEUXIEMEVOITURE, data=tableLGFinal, color=LONGUEUR)
qplot(TAUX, data=tableLGFinal, fill=LONGUEUR, bins =5)
boxplot(AGE~LONGUEUR, data=tableLGFinal, col=c("red","blue"))
qplot(SEXE, data=tableLGFinal, color=LONGUEUR)

#----------------#
# Aprendissage #
#----------------#

LG_EA <- tableLGFinal[1:7388,]
LG_ET <- tableLGFinal[7389:11082,]

#3 arbres de decision 
LGtree1 <- rpart(LONGUEUR~., LG_EA)
LG_EA$LONGUEUR <- as.factor(LG_EA$LONGUEUR)
LGtree2 <- C5.0(LONGUEUR~., LG_EA)
LGtree3 <- tree(LONGUEUR~., data=LG_EA)
#RANDOM FORESTS
rfLG <- randomForest(LONGUEUR~., LG_EA)
# SUPPORT VECTOR MACHINES
svmLG <- svm(LONGUEUR~., LG_EA, probability=TRUE)
# NAIVE BAYES
nbLG <- naive_bayes(LONGUEUR~., LG_EA)
# NEURAL NETWORKS
nnLG <- nnet(LONGUEUR~., LG_EA, size=12)
# K-NEAREST NEIGHBORS
knnLG <- kknn(LONGUEUR~., LG_EA, LG_ET)


#--------------------------------------------------#
# ##Text des classifieurs et matrice de confusion  #
#--------------------------------------------------#

##Text des arbres et matrice de confusion 
predLG.tree1 <- predict(LGtree1, LG_ET, type="class")
predLG.tree2 <- predict(LGtree2, LG_ET, type="class")
predLG.tree3 <- predict(LGtree3, LG_ET, type="class")
# Calcul des matrices de confusion
table(LG_ET$LONGUEUR, predLG.tree1)
#predLG.tree1
#courte longue moyenne tres longue
#courte        1166      1       0           1
#longue           1   1021       0           0
#moyenne        270      0       0           0
#tres longue      1    493       0         740
table(LG_ET$LONGUEUR, predLG.tree2)
#predLG.tree2
#courte longue moyenne tres longue
#courte        1166      1       0           1
#longue           1   1021       0           0
#moyenne        270      0       0           0
#tres longue      1    493       0         740
table(LG_ET$LONGUEUR, predLG.tree3)
####
#              predLG.tree3
#courte longue moyenne tres longue
#courte         940    227       0           1
#longue         304    675       0          43
#moyenne        270      0       0           0
#tres longue    163    310       0         761
##Text des classifieurs et matrice de confusion
result.rfLG <- predict(rfLG,LG_ET, type="response")
table(LG_ET$LONGUEUR, result.rfLG)
#             result.rfLG
#courte longue moyenne tres longue
#courte        1154      1      12           1
#longue           1   1015       0           6
#moyenne        258      0      12           0
#tres longue      1    491       0         742
result.svmLG <- predict(svmLG,LG_ET, type="response")
table(LG_ET$LONGUEUR, result.svmLG)
#             result.svmLG
#courte longue moyenne tres longue
#courte        1166      1       0           1
#longue           2   1020       0           0
#moyenne        270      0       0           0
#tres longue      1    493       0         740
result.treeNaiveLG <- predict(nbLG,LG_ET, type="class")
table(LG_ET$LONGUEUR, result.treeNaiveLG)
#             result.treeNaiveLG
#courte longue moyenne tres longue
#courte         332      0     684         152
#longue          12    661       2         347
#moyenne          5      0     265           0
#tres longue      7    320       0         907
result.treeNnetLG <- predict(nnLG, LG_ET,type="class")
table(LG_ET$LONGUEUR, result.treeNnetLG)
#             result.treeNnetLG
#tres longue
#courte             1168
#longue             1022
#moyenne             270
#tres longue        1234
table(LG_ET$LONGUEUR, knnLG$fitted.values)
##              courte longue moyenne tres longue
#courte        1063      1     103           1
#longue           1    744       0         277
#moyenne        154      0     116           0
#tres longue      2    355       0         877

#------------------------#
# plot arbres de decisions#
#------------------------#

##arbres de decisions
prp(LGtree1, type=4, extra=1, box.col=c("tomato", "skyblue")[LGtree1$frame$yval])
plot(LGtree2, type="simple")
plot(LGtree3)
text(LGtree3, pretty=0)

#----------------------------------------------------#
# APPLICATION DE LA METHODE rpart          #
#----------------------------------------------------#
# Visualisation des donnees a predire
View(tableMar) 

#=== rpart ===#
class.treerpLG <- predict(LGtree1, tableMar, type="class")

resultatLG <- data.frame(tableMar, class.treerpLG)

# Renommage de la colonne des classes predites
names(resultatLG)[7] <- "LONGUEUR"

#####################################################################################



#----------------------------------------#
# Le modèle de la prédiction du COULEUR#
#--------------------------------------#

#----------------------------------------#
# Preparation de donnees                #
#--------------------------------------#

tableImCL <- tableIm_f[c(6, 9)]
tableCLFinal <- merge(tableClients, tableImCL, by = "IMMATRICULATION", incomparables = NA)
#requête pour la distribution des données: OCCASION
summary(tableCLFinal$COULEUR)
##changer les types de donnees
str(tableCLFinal)
tableCLFinal$TAUX <- as.integer(tableCLFinal$TAUX)
tableCLFinal <- subset(tableCLFinal, select=-IMMATRICULATION)




####################################################################################

View(resultatLG)
View(resultatNB)
View(resultatOCCA)
View(resultatPrix)

resultatTOTAL <- data.frame(tableMar, resultatLG[7],resultatNB[7],resultatOCCA[7],resultatPrix[7] )

#---------------------------------#
# ENREGISTREMENT DES PREDICTIONS  #
#---------------------------------#
# Enregistrement du fichier de resultats au format xlsx


install.packages("openxlsx") 
library(openxlsx)
write.xlsx(resultatTOTAL,"predictions.xlsx")







