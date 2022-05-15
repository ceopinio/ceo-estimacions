#!/usr/bin/env Rscript

## Assigns a behavior to all undecided/nonrespondents (party choice
## and decision to abstain). The vote choice model assigns a party.
## The model for the decision to vote produces probabilities. In both
## cases, stores the predicted behavior for each respondent regardless
## of the answer they provided.

set.seed(314965)

library(yaml)
library(haven)
library(labelled)
library(dplyr)
library(caret); library(xgboost)
library(stringi)
library(pROC)

## ---------------------------------------- 
## Read in data and configuration

config <- read_yaml("./config/config.yaml"); attach(config)
bop <- readRDS(file.path(DTA_FOLDER, "BOP221.RDS"))

## Number of folds and repeats for repeated cv
FOLDS <- 5
REPEATS <- 5

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
## Party choice model

grid_partychoice <- expand.grid(eta=c(.01, .005, .001),
                               max_depth=c(1, 2, 3, 4, 5),
                               min_child_weight=1,
                               subsample=0.8,
                               colsample_bytree=0.8,
                               nrounds=c(1, 2, 5, 7, 10, 15)*100,
                               gamma=0)

control_partychoice <- trainControl(method="repeatedcv",
                                    number=FOLDS,
                                    repeats=REPEATS,
                                    classProbs=TRUE,                            
                                    summaryFunction=multiClassSummary)

fit_partychoice <- train(as.factor(intention) ~ .,
                        data=droplevels(subset(bop,
                                               subset=!is.na(bop$intention),
                                               select= -c(id, abstention, provincia))),
                        method="xgbTree", 
                        trControl=control_partychoice,
                        tuneGrid=grid_partychoice,
                        na.action=na.pass,
                        allowParallel=TRUE,                         
                        verbose=FALSE,
                        verbosity=0)

## Save model
m <- xgb.Booster.complete(fit_partychoice$finalModel, saveraw=FALSE)
xgb.save(m, fname=file.path(MDL_FOLDER, "model-partychoice.xgb"))
saveRDS(fit_partychoice, file.path(MDL_FOLDER, "model-partychoice.RDS"))

## Predicted party choice
p_partychoice <- predict(fit_partychoice,
                         newdata=bop,
                         na.action=na.pass,
                         type="raw")

## Save predictions to disk
bop <- droplevels(bop)

saveRDS(data.frame("id"=bop$id,
                   "p_partychoice"=p_partychoice),
        file.path(DTA_FOLDER, "predicted-partychoice.RDS"))


## ---------------------------------------- 
## Confusion matrix

confusion_matrix <- as.data.frame(prop.table(confusionMatrix(fit_partychoice)$table, 1))

p <- ggplot(confusion_matrix, aes(Prediction, Reference, fill=Freq))
pq <- p +
  geom_tile() +
  geom_text(aes(label=round(Freq, 2))) +
  scale_fill_gradient(low="white", high="#009194") +
  labs(title="Confusion matrix (% relative to reference)",
       x="Reference", y="Prediction") +
  theme(axis.text.x = element_text(angle=10, vjust=1, hjust=1))
ggsave(file.path(IMG_FOLDER, "confusion_matrix-partychoice.pdf"), pq)

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
                       probMethod="Bayes",
                       allowParallel=TRUE,
                       verbose=FALSE,
                       verbosity=0)

## Save model
m <- xgb.Booster.complete(fit_abstention$finalModel, saveraw=FALSE)
xgb.save(m, fname=file.path(MDL_FOLDER, "model-abstention.xgb"))
saveRDS(fit_abstention, file.path(MDL_FOLDER, "model-abstention.RDS"))

## Predicted abstention
bop$p_voting <- predict(fit_abstention,
                        newdata=bop,
                        na.action=na.pass,
                        type="prob")$Will.vote

saveRDS(data.frame("id"=bop$id,
                   "p_voting"=bop$p_voting),
        file.path(DTA_FOLDER, "predicted-voting.RDS"))

## Calibration
cal <- calibration(obs ~ Will.vote, data=fit_abstention$pred)

## Probability threshold to decide if voter abstains
probs <- seq(0, 1, by=0.005)
ths <- thresholder(fit_abstention, 
                   threshold=probs, ## Calculed for will vote
                   final=TRUE,
                   statistics="all")

## Threshold with max TPR and min FPR
prob <- ths[which.min(ths$Dist), "prob_threshold"]

## Save probability 
saveRDS(prob, file.path(DTA_FOLDER, "thr-predicted-voting.RDS"))

## ---------------------------------------- 
## ROC curve

best_ths <- ths[which.min(ths$Dist), ]

p <- ggplot(ths, aes(x=1 - Specificity, y=Sensitivity))
pq <- p + geom_point(shape=1) +
  geom_abline(intercept=0,
              slope=1,
              linetype="dashed") +
  geom_point(data=best_ths,
             mapping=aes(x=1 - Specificity, y=Sensitivity),
             colour="red",
             shape=17,
             size=4) +
  xlim(c(0, 1)) +
  ylim(c(0, 1)) +
  labs(title="ROC curve",
       x="False positive rate",
       y="True positive rate")

ggsave(file.path(IMG_FOLDER, "roc-abstention.pdf"), pq)

## ---------------------------------------- 
## Clean up

if (cluster) stopCluster(cl)
