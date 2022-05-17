#!/usr/bin/env Rscript

## Creates weights that match reported behavior in previous elections
## to electoral results. Non-reports are treated as having abstained.

library(yaml)
library(haven)
library(survey)
library(labelled)
library(caret); library(xgboost)
library(dplyr)

## ---------------------------------------- 
## Read in data and configuration

config <- read_yaml("./config/config.yaml"); attach(config)
bop <- readRDS(file.path(DTA_FOLDER, "BOP221.RDS"))

## Number of folds and repeats for repeated cv
FOLDS <- 5
REPEATS <- 1

## ---------------------------------------- 
## Cluster configuration

source(file.path(SRC_FOLDER, "auxiliary.R"))

cluster <- FALSE
if (file.exists(ANSIBLE_INVENTORY)) cluster <- TRUE

if (cluster) {
  cl <- set_cluster()
  registerDoParallel(cl)
}

## ---------------------------------------- 
## Results of the last election

## Information comes from the English Wiki (results from Catalan Wiki
## show some inconsistencies). Note that these results include CERA
## but ideally they wouldn't be part of the calculation. Count data is
## needed to compute the "Altres" category which is a combination of
## vote for other parties, none and null.

past_results <- c("PPC"=109453,
                  "ERC"=605581,
                  "PSC"=654766,
                  "Cs"=158606,
                  "CUP"=189924,
                  "Catalunya.en.Comu.Podem"=195345,
                  "Junts.per.Catalunya"=570539,
                  "Vox"=218121,
                  "Altres"=116993 + 24087 + 41430, # Blanc + Nul
                  "No.va.votar"=2739222)

past_results <- data.frame("p_recall"=names(past_results),
                           "Freq"=past_results/sum(past_results),
                           row.names=NULL)

## ---------------------------------------- 
## Recode past behavior 

bop$recall <- as_factor(bop$recall)

## Create an "NA" factor
bop$recall <- addNA(bop$recall)
## All nonresponse/don't recall is abstention
levels(bop$recall)[is.na(levels(bop$recall))] <- "No.va.votar"
## Data error 
levels(bop$recall)[levels(bop$recall) == "5"] <- "No.va.votar"
## Category to be predicted
levels(bop$recall)[levels(bop$recall) == "No.ho.sap"] <- NA

bop$recall <- droplevels(bop$recall)

## ---------------------------------------- 
## Predictive model

grid_recall <- expand.grid(eta=c(.01, .005, .001),
                               max_depth=c(1, 2, 3),
                               min_child_weight=1,
                               subsample=0.8,
                               colsample_bytree=0.8,
                               nrounds=seq(1, 15, length.out=20)*100,
                               gamma=0)

control_recall <- trainControl(method="repeatedcv",
                               number=FOLDS,
                               repeats=REPEATS,
                               classProbs=TRUE,
                               summaryFunction=multiClassSummary,
                               savePredictions=TRUE)

fit_recall <- train(as.factor(recall) ~ .,
                    data=droplevels(subset(bop,
                                           subset=!is.na(bop$recall),
                                           select= -c(id))),
                    method="xgbTree", 
                    trControl=control_recall,
                    tuneGrid=grid_recall,
                    na.action=na.pass,
                    allowParallel=FALSE,
                    verbose=FALSE,                        
                    verbosity=0)

## Model predictions
p_recall <- predict(fit_recall,
                    newdata=bop,
                    na.action=na.pass,
                    type="raw")

## Replace non-reporters with predicted values
bop$p_recall <- p_recall
## Anyone reporting a post behavior, keeps that behavior
bop$p_recall[!is.na(bop$recall)] <- bop$recall[!is.na(bop$recall)]
bop$p_recall <- droplevels(bop$p_recall)

## Save model
m <- xgb.Booster.complete(fit_recall$finalModel, saveraw=FALSE)
xgb.save(m, fname=file.path(MDL_FOLDER, "model-recall.xgb"))
saveRDS(fit_recall, file.path(MDL_FOLDER, "model-recall.RDS"))

## ---------------------------------------- 
## Poststratify to past electoral results

svybop <- svydesign(ids= ~1, weights= ~1, data=bop)

unweighted <- svytable(~ p_recall, svybop, Ntotal=100)

svybop <- postStratify(svybop, ~p_recall, past_results)

(svytable(~ p_recall, svybop, Ntotal=100))

(bias <- unweighted - svytable(~ p_recall, svybop, Ntotal=100))

## ---------------------------------------- 
## Save weights

weight <- weights(svybop)/mean(weights(svybop)) ## Normalize
recall_weight <- data.frame("id"=bop$id, "weight"=weight)
saveRDS(recall_weight, file.path(DTA_FOLDER, "weight.RDS"))

## ---------------------------------------- 
## Clean up

if (cluster) stopCluster(cl)
