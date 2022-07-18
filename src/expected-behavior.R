#!/usr/bin/env Rscript

## Assigns a behavior to all undecided/nonrespondents (party choice
## and decision to abstain). The vote choice model assigns a party.
## The model for the decision to vote produces probabilities. It
## stores the predicted behavior for each respondent regardless of the
## answer they provided.

set.seed(314965)

library(yaml)
library(haven)
library(labelled)
library(dplyr)
library(caret); library(xgboost)
library(MLmetrics)
library(stringi)
library(pROC)
library(doParallel)

## ---------------------------------------- 
## Read in data and configuration

list2env(read_yaml("./config/config.yaml"), envir=globalenv())
bop <- readRDS(file.path(DTA_FOLDER, "clean-bop.RDS"))

## ---------------------------------------- 
## Cluster configuration

cl <- makePSOCKcluster(detectCores() - 1)
registerDoParallel(cl)

## ---------------------------------------- 
## Party choice model

bop_intention_data <- droplevels(subset(bop, !is.na(intention)))

train_index <- createDataPartition(bop_intention_data$intention,
                                   p=.8,
                                   list=FALSE)

bop_intention_training <- bop_intention_data[ train_index, ]
bop_intention_testing  <- bop_intention_data[-train_index, ]

grid_partychoice <- expand.grid(eta=c(.1, .01, .001),
                                max_depth=c(1, 2, 3, 5, 7),
                                min_child_weight=3,
                                subsample=.8,
                                colsample_bytree=.8,
                                nrounds=seq(1, 20, length.out=20)*100,
                                gamma=0)

control_partychoice_cv <- trainControl(method="repeatedcv",
                                       number=FOLDS,
                                       repeats=1,
                                       classProbs=TRUE,                            
                                       summaryFunction=multiClassSummary)

fit_partychoice_cv <- train(as.factor(intention) ~ .,
                            data=droplevels(subset(bop_intention_training,
                                                   select= -c(id, abstention))),
                            method="xgbTree", 
                            trControl=control_partychoice_cv,
                            tuneGrid=grid_partychoice,
                            na.action=na.pass,
                            allowParallel=TRUE,                         
                            verbose=FALSE,
                            verbosity=0)

## ---------------------------------------- 
## Model evaluation

confusionMatrix(fit_partychoice_cv)

p_partychoice_testing <- predict(fit_partychoice_cv,
                                 newdata=bop_intention_testing,
                                 na.action=na.pass,
                                 type="raw")

confusionMatrix(data=p_partychoice_testing, reference=bop_intention_testing$intention)

## ---------------------------------------- 
## Re-fit on the full dataset

control_partychoice <- trainControl(method="none",
                                    classProbs=TRUE,
                                    summaryFunction=multiClassSummary,
                                    savePredictions=TRUE)

fit_partychoice <- train(as.factor(intention) ~ .,
                         data=subset(bop_intention_data,
                                     select= -c(id, abstention)),
                         method="xgbTree", 
                         trControl=control_partychoice,
                         tuneGrid=fit_partychoice_cv$bestTune,
                         na.action=na.pass,
                         allowParallel=FALSE,
                         verbose=FALSE,
                         verbosity=0)

## ---------------------------------------- 
## Final model predictions

## Predicted party choice
p_partychoice <- predict(fit_partychoice,
                         newdata=bop,
                         na.action=na.pass,
                         type="raw")

## Save model
m <- xgb.Booster.complete(fit_partychoice$finalModel, saveraw=FALSE)
xgb.save(m, fname=file.path(MDL_FOLDER, "model-partychoice.xgb"))
saveRDS(fit_partychoice, file.path(MDL_FOLDER, "model-partychoice.RDS"))

## Save predictions
saveRDS(data.frame("id"=bop$id,
                   "p_partychoice"=p_partychoice),
        file.path(DTA_FOLDER, "predicted-partychoice.RDS"))


## ---------------------------------------- 
## Confusion matrix with full model

confusion_matrix <- as.data.frame(prop.table(confusionMatrix(p_partychoice,
                                                             droplevels(bop$intention))$table,
                                             1))

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

bop_abstention_data <- droplevels(subset(bop, !is.na(abstention)))

## Predict on a simplified version
bop_abstention_data$abstention_twofactor <- as.factor(ifelse(bop_abstention_data$abstention %in%
                                                               c("Probablement aniria a votar", "Segur que aniria a votar"),
                                                             "Will.vote",
                                                             "Will.not.vote"))

train_index <- createDataPartition(bop_abstention_data$abstention_twofactor,
                                   p=.8,
                                   list=FALSE)

bop_abstention_training <- bop_abstention_data[ train_index, ]
bop_abstention_testing  <- bop_abstention_data[-train_index, ]

## Mitigates class imbalance via weights
class_weights <- ifelse(bop_abstention_training$abstention_twofactor == "Will.not.vote", 5, 1)

grid_abstention <- expand.grid(eta=c(.1, .01, .001),
                               max_depth=c(1, 2, 3, 5, 7),
                               min_child_weight=3,
                               subsample=.8,
                               colsample_bytree=.8,
                               nrounds=seq(1, 20, length.out=20)*100,
                               gamma=0)

control_abstention_cv <- trainControl(method="repeatedcv",
                                      number=FOLDS,
                                      repeats=5,
                                      classProbs=TRUE,
                                      savePredictions=TRUE)

fit_abstention_cv <- train(as.factor(abstention_twofactor) ~ .,
                           data=droplevels(subset(bop_abstention_training,
                                                  select= -c(id, intention, abstention))), 
                           method="xgbTree", 
                           trControl=control_abstention_cv,
                           tuneGrid=grid_abstention,
                           na.action=na.pass,
                           probMethod="Bayes",
                           weights=class_weights,
                           allowParallel=TRUE,
                           verbose=FALSE,
                           verbosity=0)

## ---------------------------------------- 
## Model evaluation

confusionMatrix(fit_abstention_cv)

p_abstention_testing <- predict(fit_abstention_cv,
                                newdata=bop_abstention_testing,
                                na.action=na.pass,
                                type="raw")

confusionMatrix(data=p_abstention_testing, reference=bop_abstention_testing$abstention_twofactor)

## ---------------------------------------- 
## Re-fit on the full dataset

control_abstention <- trainControl(method="none",
                                   classProbs=TRUE,
                                   savePredictions=TRUE)

class_weights <- ifelse(bop_abstention_data$abstention_twofactor == "Will.not.vote", 5, 1)

fit_abstention <- train(as.factor(abstention_twofactor) ~ .,
                        data=subset(bop_abstention_data,
                                    select= -c(id, intention, abstention)),
                        method="xgbTree", 
                        trControl=control_abstention,
                        tuneGrid=fit_abstention_cv$bestTune,
                        na.action=na.pass,
                        probMethod="Bayes",
                        weights=class_weights,
                        allowParallel=FALSE,
                        verbose=FALSE,
                        verbosity=0)

## ---------------------------------------- 
## Final model predictions

## Predicted intention to vote
bop$p_voting <- predict(fit_abstention,
                        newdata=bop,
                        na.action=na.pass,
                        type="prob")$Will.vote

## Save model
m <- xgb.Booster.complete(fit_abstention$finalModel, saveraw=FALSE)
xgb.save(m, fname=file.path(MDL_FOLDER, "model-abstention.xgb"))
saveRDS(fit_abstention, file.path(MDL_FOLDER, "model-abstention.RDS"))

## Save predictions 
saveRDS(data.frame("id"=bop$id,
                   "p_voting"=bop$p_voting),
        file.path(DTA_FOLDER, "predicted-voting.RDS"))

## ---------------------------------------- 
## Calibration

cal <- calibration(obs ~ Will.vote, data=fit_abstention_cv$pred)

## Probability threshold to decide if voter abstains
probs <- seq(0, 1, by=0.005)
ths <- thresholder(fit_abstention_cv, 
                   threshold=probs, ## Calculated for will vote
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

stopCluster(cl)
