#!/usr/bin/env Rscript

## Assigns a behavior to all undecided/nonrespondents (party choice
## and decision to abstain). The vote choice model assigns a party.
## The model for the decision to vote produces probabilities. It
## stores the predicted behavior for each respondent regardless of the
## answer they provided.

set.seed(250424)

library(yaml)
library(haven)
library(labelled)
library(dplyr)
library(caret); library(xgboost)
library(MLmetrics)
library(stringi)
library(pROC)
library(doParallel)
library(tidyverse)

## ---------------------------------------- 
## Read in data and configuration

list2env(read_yaml("./config/config.yaml"), envir=globalenv())
df <- readRDS(file.path(DTA_FOLDER, "clean-df.RDS"))

## ---------------------------------------- 
## Cluster configuration

cl <- makePSOCKcluster(detectCores() - 1)
registerDoParallel(cl)

## ---------------------------------------- 
## Party choice model
levels(df$intention) <- paste0("p", levels(df$intention))

df_intention_data <- droplevels(subset(df, !is.na(intention)))

train_index <- createDataPartition(df_intention_data$intention,
                                   p=.8,
                                   list=FALSE)

df_intention_training <- df_intention_data[ train_index, ]
df_intention_testing  <- df_intention_data[-train_index, ]

    # Adjusting the grid might make the model better but computational time increases
grid_partychoice <- expand.grid(eta=c(.1, .01),
                            max_depth=c(1, 3, 5),
                            min_child_weight=c(1, 3),
                            subsample=.8,
                            colsample_bytree=.8,
                            nrounds=c(10, 50), 
                            gamma=0)

control_partychoice_cv <- trainControl(method="repeatedcv",
                                       number=FOLDS,
                                       repeats=REPEATS,
                                       classProbs=TRUE,                            
                                       summaryFunction=multiClassSummary)

fit_partychoice_cv <- train(as.factor(intention) ~ .,
                            data=droplevels(select(df_intention_training,
                                                   -c(id, abstention, starts_with("doubting_")))), # doubting variables cannot be used for training
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
                                 newdata=df_intention_testing,
                                 na.action=na.pass,
                                 type="raw")

confusionMatrix(data=p_partychoice_testing, reference=df_intention_testing$intention)

## ---------------------------------------- 
## Re-fit on the full dataset

control_partychoice <- trainControl(method="none",
                                    classProbs=TRUE,
                                    summaryFunction=multiClassSummary,
                                    savePredictions=TRUE)

fit_partychoice <- train(as.factor(intention) ~ .,
                         data=select(df_intention_data,
                                     -c(id, abstention, starts_with("doubting_"))), # doubting variables cannot be used for training
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
                         newdata=df,
                         na.action=na.pass,
                         type="raw")

## Save model
m <- xgb.Booster.complete(fit_partychoice$finalModel, saveraw=FALSE)
xgb.save(m, fname=file.path(MDL_FOLDER, "model-partychoice.xgb"))
saveRDS(fit_partychoice, file.path(MDL_FOLDER, "model-partychoice.RDS"))


## Do not change people that said an intention
partychoice_df <- data.frame("id"=df$id,
           "p_partychoice"=p_partychoice,
           "intention"=df$intention) %>% 
  mutate(p_partychoice = if_else(is.na(intention), p_partychoice, intention)) %>% 
  mutate(predicted = if_else(is.na(intention), 1, 0)) %>% 
  select(-intention)

## If people said they are doubting between X parties, and prediction is to other parties, take 
## the party within the X ones that the prediction gives more probability to.

## Take probabilities
p_partychoice_prob <- predict(fit_partychoice, newdata=df, na.action=na.pass, type="prob")
p_partychoice_prob <- data.frame(id = df$id, p_partychoice_prob)

# Change party choice using the information about the doubt of the person
change_partychoice_doubt <- partychoice_df %>% 
  left_join(p_partychoice_prob, by = "id") %>% 
  left_join(select(df, id, starts_with("doubting_")), by = "id") %>% 
  mutate(across(starts_with("doubting_"), ~as.numeric(.)-1)) %>%
  filter(predicted == 1) %>%
  mutate(no_doubting_data = if_else(rowSums(select(., starts_with("doubting_"))) <= 1, 1, 0)) %>% 
  mutate(no_doubting_data = if_else(is.na(no_doubting_data), 1, no_doubting_data)) %>% 
  filter(no_doubting_data == 0) %>% 
  mutate(p_partychoice_new = case_when(
    p_partychoice == "p1" & doubting_p1 == 1 ~ "p1",
    p_partychoice == "p1" & doubting_p1 == 0 ~ NA_character_,
    p_partychoice == "p3" & doubting_p3 == 1 ~ "p3",
    p_partychoice == "p3" & doubting_p3 == 0 ~ NA_character_,
    p_partychoice == "p4" & doubting_p4 == 1 ~ "p4",
    p_partychoice == "p4" & doubting_p4 == 0 ~ NA_character_,
    p_partychoice == "p6" & doubting_p6 == 1 ~ "p6",
    p_partychoice == "p6" & doubting_p6 == 0 ~ NA_character_,
    p_partychoice == "p10" & doubting_p10 == 1 ~ "p10",
    p_partychoice == "p10" & doubting_p10 == 0 ~ NA_character_,
    p_partychoice == "p18" & doubting_p18 == 1 ~ "p18",
    p_partychoice == "p18" & doubting_p18 == 0 ~ NA_character_,
    p_partychoice == "p21" & doubting_p21 == 1 ~ "p21",
    p_partychoice == "p21" & doubting_p21 == 0 ~ NA_character_,
    p_partychoice == "p23" & doubting_p23 == 1 ~ "p23",
    p_partychoice == "p23" & doubting_p23 == 0 ~ NA_character_,
    p_partychoice == "p25" & doubting_p25 == 1 ~ "p25",
    p_partychoice == "p25" & doubting_p25 == 0 ~ NA_character_,
    p_partychoice == "p80"~ NA_character_,
  )) %>% 
  filter(is.na(p_partychoice_new)) %>% 
  select(-predicted) %>% 
  pivot_longer(cols = c("p1", "p3", "p4", "p6", "p10", "p18", "p21", "p23", "p25", "p80"), 
               names_to = "party", 
               values_to = "p") %>% 
  mutate(doubt = case_when(
    party == "p1" & doubting_p1 == 1 ~ 1,
    party == "p3" & doubting_p3 == 1 ~ 1,
    party == "p4" & doubting_p4 == 1 ~ 1,
    party == "p6" & doubting_p6 == 1 ~ 1,
    party == "p10" & doubting_p10 == 1 ~ 1,
    party == "p18" & doubting_p18 == 1 ~ 1,
    party == "p21" & doubting_p21 == 1 ~ 1,
    party == "p23" & doubting_p23 == 1 ~ 1,
    party == "p25" & doubting_p25 == 1 ~ 1,
    TRUE ~ NA
  )) %>% 
  select(-starts_with("doubting_")) %>% 
  filter(doubt == 1) %>% 
  group_by(id) %>% 
  filter(row_number() == which.max(p)) %>% 
  select(-no_doubting_data, -p, -doubt, -p_partychoice_new) %>% 
  rename("p_partychoice_new" = "party")
  
partychoice_df <- partychoice_df %>% 
  left_join(select(change_partychoice_doubt, id, p_partychoice_new), by = "id") %>%
  mutate(p_partychoice = if_else(is.na(p_partychoice_new), p_partychoice, p_partychoice_new))

## Save predictions
saveRDS(partychoice_df, file.path(DTA_FOLDER, "predicted-partychoice.RDS"))


## ---------------------------------------- 
## Confusion matrix with full model

confusion_matrix <- as.data.frame(prop.table(confusionMatrix(p_partychoice, droplevels(df$intention))$table, 1))

p <- ggplot(confusion_matrix, aes(Reference, Prediction, fill=Freq))
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

df_abstention_data <- droplevels(subset(df, !is.na(abstention)))

## Predict on a simplified version
df_abstention_data$abstention_twofactor <- as.factor(ifelse(df_abstention_data$abstention %in% c(3, 4), "Will.vote", "Will.not.vote"))

train_index <- createDataPartition(df_abstention_data$abstention_twofactor,
                                   p=.8,
                                   list=FALSE)

df_abstention_training <- df_abstention_data[ train_index, ]
df_abstention_testing  <- df_abstention_data[-train_index, ]

## Mitigates class imbalance via weights
class_weights <- ifelse(df_abstention_training$abstention_twofactor == "Will.not.vote", 6, 1)

    # Adjusting the grid might make the model better but computational time increases
grid_abstention <- expand.grid(eta=c(.1, .01),
                              max_depth=c(1, 3, 5),
                                min_child_weight=c(1, 3),
                                subsample=.8,
                                colsample_bytree=.8,
                                nrounds=c(10, 50), 
                                gamma=0)

control_abstention_cv <- trainControl(method="repeatedcv",
                                      number=FOLDS,
                                      repeats=REPEATS,
                                      classProbs=TRUE,
                                      savePredictions=TRUE)

fit_abstention_cv <- train(as.factor(abstention_twofactor) ~ .,
                           data=droplevels(select(df_abstention_training,
                                                  -c(id, intention, abstention))), 
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
                                newdata=df_abstention_testing,
                                na.action=na.pass,
                                type="raw")

confusionMatrix(data=p_abstention_testing, reference=df_abstention_testing$abstention_twofactor)

## ---------------------------------------- 
## Re-fit on the full dataset

control_abstention <- trainControl(method="none",
                                   classProbs=TRUE,
                                   savePredictions=TRUE)

class_weights <- ifelse(df_abstention_data$abstention_twofactor == "Will.not.vote", 6, 1)

fit_abstention <- train(as.factor(abstention_twofactor) ~ .,
                        data=subset(df_abstention_data,
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
df$p_voting <- predict(fit_abstention,
                        newdata=df,
                        na.action=na.pass,
                        type="prob")$Will.vote

## Save model
m <- xgb.Booster.complete(fit_abstention$finalModel, saveraw=FALSE)
xgb.save(m, fname=file.path(MDL_FOLDER, "model-abstention.xgb"))
saveRDS(fit_abstention, file.path(MDL_FOLDER, "model-abstention.RDS"))

## Save predictions 
saveRDS(data.frame("id"=df$id,
                   "p_voting"=df$p_voting),
        file.path(DTA_FOLDER, "predicted-voting.RDS"))

## ---------------------------------------- 
## Calibration

cal <- calibration(obs ~ Will.vote, data=fit_abstention_cv$pred)

## Probability threshold to decide if voter abstains
probs <- seq(0, 1, by=0.005)
ths <- thresholder(fit_abstention_cv, 
                   threshold=probs, ## Calculated for will vote
                   final=TRUE,
                   statistics=c("Sensitivity",
                                "Specificity",
                                "Accuracy",
                                "Kappa",
                                "J",
                                "Dist"))

## Threshold with max TPR and min FPR
## We add the restriction to prioritize not having false positives
ths_filtered <- ths[ths$Specificity > 0.983, ]
prob <- ths_filtered[which.min(ths_filtered$Dist), "prob_threshold"]

## Save probability 
saveRDS(prob, file.path(DTA_FOLDER, "thr-predicted-voting.RDS"))

## ---------------------------------------- 
## ROC curve

best_ths <- ths[ths$prob_threshold == prob, ]

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
