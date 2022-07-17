#!/usr/bin/env Rscript

## Creates weights that match reported behavior in previous elections
## to electoral results. Non-reports are assigned a behavior based on
## a predictive model.

set.seed(314965)

library(yaml)
library(haven)
library(survey)
library(labelled)
library(caret); library(xgboost)
library(dplyr)
library(doParallel)

## ---------------------------------------- 
## Read in data and configuration

list2env(read_yaml("./config/config.yaml"), envir=globalenv())
bop <- readRDS(file.path(DTA_FOLDER, "clean-bop.RDS"))

past_results <- read.csv(file.path(RAW_DTA_FOLDER, "results-2021.csv"))

## ---------------------------------------- 
## Cluster configuration

cl <- makePSOCKcluster(detectCores() - 1)
registerDoParallel(cl)

## ---------------------------------------- 
## Results of the last election

results <- past_results |>
  mutate(party=case_when(party %in% c("Nul", "Blanc", "Altres.partits") ~
                           "Altres.partits",
                         TRUE ~ party)) |>
  group_by(party) |>
  summarize(votes=sum(votes)) |>
  as.data.frame()

No.va.votar <- results[results$party == "Censo", "votes"] -
  sum(results[results$party != "Censo", "votes"])

results <- rbind(results, list("No.va.votar", No.va.votar))
results <- subset(results, party != "Censo")

past_results <- data.frame("p_recall"=results$party,
                           "Freq"=results$votes/sum(results$votes),
                           row.names=NULL)

## ---------------------------------------- 
## Recode past behavior 

bop$recall <- as_factor(bop$recall)

## Create an "NA" factor
bop$recall <- addNA(bop$recall)
## All nonresponse/don't recall is abstention
levels(bop$recall)[is.na(levels(bop$recall))] <- "No.va.votar"
## Category to be predicted
levels(bop$recall)[levels(bop$recall) == "No.ho.sap"] <- NA
## Rename category for consistency
levels(bop$recall)[levels(bop$recall) == "Altres"] <- "Altres.partits"


## ---------------------------------------- 
## Predictive model

bop_recall_data <- droplevels(subset(bop, !is.na(recall)))

train_index <- createDataPartition(bop_recall_data$recall,
                                   p=.8,
                                   list=FALSE)

bop_recall_training <- bop_recall_data[ train_index, ]
bop_recall_testing  <- bop_recall_data[-train_index, ]

grid_recall <- expand.grid(eta=c(0.1, .01, .005, .001),
                           max_depth=c(1, 2, 3, 4, 5, 7),
                           min_child_weight=c(1, 3, 5),
                           subsample=c(0.7, 0.8, 1),
                           colsample_bytree=c(0.7, 0.8, 1),
                           nrounds=seq(1, 20, length.out=25)*100,
                           gamma=0)

control_recall_cv <- trainControl(method="repeatedcv",
                                  number=FOLDS,
                                  repeats=REPEATS,
                                  classProbs=TRUE,
                                  summaryFunction=multiClassSummary,
                                  savePredictions=TRUE)

fit_recall_cv <- train(as.factor(recall) ~ .,
                       data=droplevels(subset(bop_recall_training,
                                              select= -id)),
                       method="xgbTree", 
                       trControl=control_recall_cv,
                       tuneGrid=grid_recall,
                       na.action=na.pass,
                       allowParallel=FALSE,
                       verbose=FALSE,
                       verbosity=0)

## ---------------------------------------- 
## Model evaluation

confusionMatrix(fit_recall_cv)

p_recall_testing <- predict(fit_recall_cv,
                            newdata=bop_recall_testing,
                            na.action=na.pass,
                            type="raw")

confusionMatrix(data=p_recall_testing, reference=bop_recall_testing$recall)

## ---------------------------------------- 
## Re-fit on the full dataset

control_recall <- trainControl(method="none",
                               classProbs=TRUE,
                               summaryFunction=multiClassSummary,
                               savePredictions=TRUE)

fit_recall <- train(as.factor(recall) ~ .,
                    data=subset(bop_recall_data,
                                select= -id),
                    method="xgbTree", 
                    trControl=control_recall,
                    tuneGrid=fit_recall_cv$bestTune,
                    na.action=na.pass,
                    allowParallel=FALSE,
                    verbose=FALSE,
                    verbosity=0)

## ---------------------------------------- 
## Final model predictions

p_recall <- predict(fit_recall,
                    newdata=bop,
                    na.action=na.pass,
                    type="raw")

## Replace non-reporters with predicted values
bop$p_recall <- p_recall
## Anyone reporting a post behavior, keeps that behavior
bop$p_recall[!is.na(bop$recall)] <- bop$recall[!is.na(bop$recall)]

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

## ---------------------------------------- 
## Save weights

weight <- weights(svybop)/mean(weights(svybop)) ## Normalize
recall_weight <- data.frame("id"=bop$id, "weight"=weight)
saveRDS(recall_weight, file.path(DTA_FOLDER, "weight.RDS"))

## ---------------------------------------- 
## Clean up

stopCluster(cl)
