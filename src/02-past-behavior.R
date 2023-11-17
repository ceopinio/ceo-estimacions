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
library(MLmetrics)
library(dplyr)
library(doParallel)

## ---------------------------------------- 
## Read in data and configuration

list2env(read_yaml("./config/config.yaml"), envir=globalenv())
bop <- readRDS(file.path(DTA_FOLDER, "clean-bop.RDS"))

past_results <- read_delim(file.path(RAW_DTA_FOLDER, "results-2023.csv"), delim = ";", escape_double = FALSE, trim_ws = TRUE)
llengua_primera <- read_delim(file.path(RAW_DTA_FOLDER, "llengua.csv"),  delim = ";", escape_double = FALSE, trim_ws = TRUE)

## ---------------------------------------- 
## Cluster configuration

cl <- makePSOCKcluster(detectCores() - 1)
registerDoParallel(cl)

## ---------------------------------------- 
## Results of the last election

results <- past_results |>
  mutate(code=case_when(code %in% c(93, 94, 80, 6) ~ #Nul, Blanc, Altres, 
                          80,
                        TRUE ~ code)) |>
  group_by(code) |>
  summarize(votes=sum(votes)) |>
  as.data.frame()

No.va.votar <- results[results$code == 8000, "votes"] -
  sum(results[results$code != 8000, "votes"])

results <- rbind(results, list(9000, No.va.votar))
results <- subset(results, code != 8000)

past_results <- data.frame("p_recall"=paste0("p", results$code),
                           "Freq"=results$votes/sum(results$votes)*nrow(bop),
                           row.names=NULL) |>
  mutate( p_recall = ifelse(p_recall == "p22", "p18", p_recall))

## ---------------------------------------- 
## Distribution of language use

pop_llengua <- data.frame("llengua_primera"=llengua_primera$code,
                          "Freq"=llengua_primera$Freq*nrow(bop))

## ---------------------------------------- 
## Recode past behavior 

bop$recall <- as_factor(bop$recall)

## Create an "NA" factor
bop$recall <- addNA(bop$recall)
## All nonresponse/don't recall is abstention
levels(bop$recall)[is.na(levels(bop$recall))] <- "9000"
## Category to be predicted
levels(bop$recall)[levels(bop$recall) == "98"] <- NA


## ---------------------------------------- 
## Predictive model

## it doesn't accept levels started with number
levels(bop$recall) <- paste0("p", levels(bop$recall))

bop_recall_data <- droplevels(subset(bop, !is.na(recall)))

train_index <- createDataPartition(bop_recall_data$recall,
                                   p=.8,
                                   list=FALSE)

bop_recall_training <- bop_recall_data[ train_index, ]
bop_recall_testing  <- bop_recall_data[-train_index, ]

grid_recall <- expand.grid(eta=c(.1, .01, .001),
                           max_depth=c(1, 2, 3, 5, 7),
                           min_child_weight=c(1, 3, 5),
                           subsample=.8,
                           colsample_bytree=.8,
                           nrounds=seq(1, 20, length.out=20)*100,
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

## Save predictions
saveRDS(data.frame("id"=bop$id,
                   "p_recall"=bop$p_recall),
        file.path(DTA_FOLDER, "predicted-recall.RDS"))


## ---------------------------------------- 
## Poststratify to language and past electoral results

## Impute missings to Other
bop$llengua_primera[is.na(bop$llengua_primera)] <- 80
bop$llengua_primera <- as.numeric(as.character(bop$llengua_primera))

svybop <- svydesign(ids= ~1, weights= ~1, data=bop)

svybop <- rake(design=svybop,
               sample.margins=list(~p_recall, ~llengua_primera),
               population.margins=list(past_results, pop_llengua))

(svytable(~ p_recall, svybop, Ntotal=100))
(svytable(~ llengua_primera, svybop, Ntotal=100))

## ---------------------------------------- 
## Save weights

weight <- weights(svybop)/mean(weights(svybop)) ## Normalize
recall_weight <- data.frame("id"=bop$id, "weight"=weight)
saveRDS(recall_weight, file.path(DTA_FOLDER, "weight.RDS"))

## ---------------------------------------- 
## Clean up

stopCluster(cl)
