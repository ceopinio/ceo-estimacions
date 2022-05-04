#!/usr/bin/env Rscript

## Assigns a behavior to all undecided/nonrespondents (party choice and
## decision to abstain). The vote choice model assigns a party. The
## model for the decision assigns a produces probabilities. In both
## cases, stores the predicted behavior for each respondent regardless
## of the answer they provided.

## Assumes access to a cluster. The IPs for workers are assumed to be
## stored in an Ansible inventory file. To run in local, disable the
## "Cluster configuration" section of the script.

set.seed(314965)

library(yaml)
library(haven)
library(labelled)
library(dplyr)
library(caret); library(xgboost)
library(stringi)
library(pROC)
library(doParallel)

## ---------------------------------------- 
## Read in data and configuration

config <- read_yaml("./config/config.yaml")
bop <- readRDS(file.path(config$DTA_FOLDER, "BOP221.RDS"))

## Number of folds and repeats for repeated cv
FOLDS <- 5
REPEATS <- 5

## ---------------------------------------- 
## Cluster configuration

inventory <- read_yaml("./ansible/inventory") 
sshkey <- inventory$droplet$vars$ansible_ssh_private_key_file
workersips <- names(inventory$droplet$hosts)
localhostip <- read_yaml("./ansible/localhost")

## Make cluster
cl <- makePSOCKcluster(names=c("localhost", workersips), 
                       master=localhostip,
                       user="root",
                       homogeneous=FALSE,
                       useXDR=FALSE,
                       outfile="cluster-log.txt",
                       rscript="/usr/bin/Rscript",
                       rshopts=c("-o", "StrictHostKeyChecking=no",
                                 "-o", "IdentitiesOnly=yes",
                                 "-i", sshkey))

registerDoParallel(cl)

## ---------------------------------------- 
## Party choice model

grid_partychoice <- expand.grid(eta=c(.1, .05, .01, .005),
                                max_depth=c(1, 2, 3, 4, 5),
                                min_child_weight=1,
                                subsample=0.8,
                                colsample_bytree=0.8,
                                nrounds=c(.5, 1, 2, 5, 7, 10, 15)*100,
                                gamma=0)

control_partychoice <- trainControl(method="repeatedcv",
                                    number=FOLDS,
                                    repeats=REPEATS,
                                    classProbs=TRUE,                            
                                    summaryFunction=multiClassSummary)

fit_partychoice <- train(as.factor(intention) ~ .,
                         data=droplevels(subset(bop,
                                                subset=!is.na(bop$intention),
                                                select= -c(id, abstention))), 
                         method="xgbTree", 
                         trControl=control_partychoice,
                         tuneGrid=grid_partychoice,
                         na.action=na.pass,
                         allowParallel=TRUE,                         
                         verbose=FALSE,
                         verbosity=0)

## Save model
m <- xgb.Booster.complete(fit_partychoice$finalModel, saveraw=FALSE)
xgb.save(m, fname=file.path(config$MDL_FOLDER, "model-partychoice.xgb"))
saveRDS(fit_partychoice, file.path(config$MDL_FOLDER, "model-partychoice.RDS"))

## Predicted party choice
p_partychoice <- predict(fit_partychoice,
                         newdata=bop,
                         na.action=na.pass,
                         type="raw")

## Save predictions to disk
bop <- droplevels(bop)

saveRDS(data.frame("id"=bop$id,
                   "p_partychoice"=p_partychoice),
        file.path(config$DTA_FOLDER, "predicted-partychoice.RDS"))


## ---------------------------------------- 
## Abstention model

grid_abstention <- expand.grid(eta=c(.01, .005, .001),
                               max_depth=c(1, 2, 3, 4, 5),
                               min_child_weight=1,
                               subsample=0.8,
                               colsample_bytree=0.8,
                               nrounds=c(1, 2, 5, 7, 10, 15)*100,
                               gamma=0)

control_abstention <- trainControl(method="repeatedcv",
                                   number=FOLDS,
                                   repeats=REPEATS,
                                   classProbs=TRUE,
                                   summaryFunction=multiClassSummary,
                                   savePredictions=TRUE)

fit_abstention <- train(as.factor(abstention) ~ .,
                        data=droplevels(subset(bop,
                                               subset=!is.na(bop$abstention),
                                               select= -c(id, intention))), 
                        method="xgbTree", 
                        trControl=control_abstention,
                        tuneGrid=grid_abstention,
                        na.action=na.pass,
                        allowParallel=TRUE,
                        verbose=FALSE,                        
                        verbosity=0)

## Save model
m <- xgb.Booster.complete(fit_abstention$finalModel, saveraw=FALSE)
xgb.save(m, fname=file.path(config$MDL_FOLDER, "model-abstention.xgb"))
saveRDS(fit_abstention, file.path(config$MDL_FOLDER, "model-abstention.RDS"))

## Predicted abstention
bop$p_abstention <- predict(fit_abstention,
                            newdata=bop,
                            na.action=na.pass,
                            type="prob")$Will.not.vote

saveRDS(data.frame("id"=bop$id,
                   "p_abstention"=bop$p_abstention),
        file.path(config$DTA_FOLDER, "predicted-abstention.RDS"))

## Probability threshold to decide if voter abstains
probs <- seq(.1, .9, by=0.005)
ths <- thresholder(fit_abstention,
                   threshold=probs,
                   final=TRUE,
                   statistics="all")

## Threshold with max TPR and min FPR
prob <- ths[which.min(ths$Dist), "prob_threshold"] 

## Save probability 
saveRDS(prob, file.path(config$DTA_FOLDER, "thr-predicted-abstention.RDS"))

## ---------------------------------------- 
## Clean up

stopCluster(cl)

