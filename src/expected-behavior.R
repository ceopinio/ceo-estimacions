#!/usr/bin/env Rscript

## Description: Estimation of individual behavior
## Author: Gonzalo Rivero
## Date: 07-Apr-2022 20:04

set.seed(314965)

library(yaml)
library(haven)
library(labelled)
library(dplyr)
library(caret); library(xgboost)
library(stringi)
library(pROC)

FOLDS <- 5
REPEATS <- 5

config <- read_yaml("./config/config.yaml")

bop <- readRDS(file.path(config$DTA_FOLDER, "BOP221.RDS"))

## Parameter search
grid_partychoice <- expand.grid(eta=c(.1, .05, .01, .005, .001),
                                max_depth=c(1, 2, 3),
                                min_child_weight=1,
                                subsample=0.8,
                                colsample_bytree=0.8,
                                nrounds=c(.5, 1, 2, 5, 7, 10)*100,
                                gamma=0)

control_partychoice <- trainControl(method="repeatedcv",
                                    number=FOLDS,
                                    repeats=REPEATS,
                                    classProbs=TRUE,                            
                                    summaryFunction=multiClassSummary)

fit_partychoice <- train(as.factor(intention) ~ .,
                         data=droplevels(subset(bop,
                                                subset=!is.na(bop$intention),
                                                select= -abstention)), 
                         method="xgbTree", 
                         trControl=control_partychoice,
                         tuneGrid=grid_partychoice,
                         na.action=na.pass,
                         verbose=FALSE,
                         verbosity=0)

## Save model
m <- xgb.Booster.complete(fit_partychoice$finalModel, saveraw=FALSE)
xgb.save(m, fname=file.path(config$DTA_FOLDER, "fit-partychoice.model"))
saveRDS(fit_partychoice, file.path(config$DTA_FOLDER, "fit-partychoice.RDS"))


#################### Vote or not ####################
grid_abstention <- expand.grid(eta=c(.01, .005, .001),
                               max_depth=c(1, 2, 3),
                               min_child_weight=1,
                               subsample=0.8,
                               colsample_bytree=0.8,
                               nrounds=c(1, 2, 5, 7, 10)*100,
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
                                               select= -intention)), 
                        method="xgbTree", 
                        trControl=control_abstention,
                        tuneGrid=grid_abstention,
                        na.action=na.pass,
                        verbose=FALSE,
                        verbosity=0)

## Save model
m <- xgb.Booster.complete(fit_abstention$finalModel, saveraw=FALSE)
xgb.save(m, fname=file.path(config$DTA_FOLDER, "fit-abstention.model"))
saveRDS(fit_abstention, file.path(config$DTA_FOLDER, "fit-abstention.RDS"))
