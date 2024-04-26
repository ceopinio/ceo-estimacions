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
library(tidyverse)

## ---------------------------------------- 
## Read in data and configuration

list2env(read_yaml("./config/config.yaml"), envir=globalenv())
df <- readRDS(file.path(DTA_FOLDER, "clean-df.RDS"))

past_results <- readr::read_delim(file.path(RAW_DTA_FOLDER, "results-2021.csv"), delim = ";", escape_double = FALSE, trim_ws = TRUE)
population_data <- readr::read_delim(file.path(RAW_DTA_FOLDER, "poblacio.csv"),  delim = ";", escape_double = FALSE, trim_ws = TRUE)

## ---------------------------------------- 
## Cluster configuration

cl <- makePSOCKcluster(detectCores() - 1)
registerDoParallel(cl)

## ---------------------------------------- 
## Results of the last election

results <- past_results |>
  mutate(code=case_when(code %in% c(93, 94, 80) ~ #Nul, Blanc, Altres
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
                           "Freq"=results$votes/sum(results$votes)*nrow(df),
                           row.names=NULL) |>
  mutate( p_recall = ifelse(p_recall == "p22", "p18", p_recall))

## ---------------------------------------- 
## Recode past behavior 

df$recall <- as_factor(df$recall)

## Create an "NA" factor
df$recall <- addNA(df$recall)

## All nonresponse/don't recall is abstention
levels(df$recall)[is.na(levels(df$recall))] <- "9000"

## Category to be predicted
levels(df$recall)[levels(df$recall) == "98"] <- NA


## ---------------------------------------- 
## Predictive model

## it doesn't accept levels started with number
levels(df$recall) <- paste0("p", levels(df$recall))

df_recall_data <- droplevels(subset(df, !is.na(recall)))

train_index <- createDataPartition(df_recall_data$recall,
                                   p=.8,
                                   list=FALSE)

df_recall_training <- df_recall_data[ train_index, ]
df_recall_testing  <- df_recall_data[-train_index, ]

    # Adjusting the grid might make the model better but computational time increases
grid_recall <- expand.grid(eta=c(.1, .01),
                            max_depth=c(1, 3, 5),
                            min_child_weight=c(1, 3),
                            subsample=.8,
                            colsample_bytree=.8,
                            nrounds=c(10, 50), 
                            gamma=0)

control_recall_cv <- trainControl(method="repeatedcv",
                                  number=FOLDS,
                                  repeats=REPEATS,
                                  classProbs=TRUE,
                                  summaryFunction=multiClassSummary,
                                  savePredictions=TRUE)

fit_recall_cv <- train(as.factor(recall) ~ .,
                       data=droplevels(subset(df_recall_training,
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
                            newdata=df_recall_testing,
                            na.action=na.pass,
                            type="raw")

confusionMatrix(data=p_recall_testing, reference=df_recall_testing$recall)

## ---------------------------------------- 
## Re-fit on the full dataset

control_recall <- trainControl(method="none",
                               classProbs=TRUE,
                               summaryFunction=multiClassSummary,
                               savePredictions=TRUE)

fit_recall <- train(as.factor(recall) ~ .,
                    data=subset(df_recall_data,
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
                    newdata=df,
                    na.action=na.pass,
                    type="raw")

## Replace non-reporters with predicted values
df$p_recall <- p_recall
## Anyone reporting a post behavior, keeps that behavior
df$p_recall[!is.na(df$recall)] <- df$recall[!is.na(df$recall)]

## Save model
m <- xgb.Booster.complete(fit_recall$finalModel, saveraw=FALSE)
xgb.save(m, fname=file.path(MDL_FOLDER, "model-recall.xgb"))
saveRDS(fit_recall, file.path(MDL_FOLDER, "model-recall.rds"))

## Save predictions
saveRDS(data.frame("id"=df$id,
                   "p_recall"=df$p_recall),
        file.path(DTA_FOLDER, "predicted-recall.rds"))


## ---------------------------------------- 
## Poststratify to language, studies and past electoral results

## Adjust population data
population_data <- population_data |> 
  dplyr::select(identificador, codi_resposta, esp_18, any) |>
  group_by(identificador, codi_resposta) |>
  filter(any == max(any)) |>
  ungroup() |>
  mutate(esp_18 = as.numeric(gsub(",", ".", esp_18)))

## Population distribution for language
pop_llengua <- population_data |>
  filter(identificador == "LLENGUA_PRIMERA") |>
  rename("llengua_primera" = "codi_resposta") |>
  mutate(Freq = esp_18/100 * nrow(df)) |>
  dplyr::select(-c(identificador, any, esp_18))

## Population distribution for studies
pop_estudis <- population_data |>
  filter(identificador == "ESTUDIS") |>
  rename("estudis_1_3" = "codi_resposta") |>
  mutate(Freq = esp_18/100 * nrow(df)) |>
  dplyr::select(-c(identificador, any, esp_18))

## Population distribution for birthplace
pop_lloc_naix <- population_data |>
  filter(identificador == "LLOC_NAIX") |>
  rename("lloc_naix" = "codi_resposta") |>
  mutate(Freq = esp_18/100 * nrow(df)) |>
  dplyr::select(-c(identificador, any, esp_18))

## Impute missings to Other language
df$llengua_primera[is.na(df$llengua_primera)] <- 80
df$llengua_primera <- as.numeric(as.character(df$llengua_primera))

## Impute missings to lower studies
df$estudis_1_6[is.na(df$estudis_1_6)] <- 1
# Convert studies from 6 levels to 3
df <- df |>
  mutate(estudis_1_3 = case_when(
    estudis_1_6 %in% c(1,2) ~ 1,
    estudis_1_6 %in% c(3,4) ~ 2,
    estudis_1_6 %in% c(5,6) ~ 3
  ))

## Convert birthplace to same format as population data
df <- df |>
  mutate(lloc_naix = case_when(
    lloc_naix %in% c("Catalunya") ~ 1,
    lloc_naix %in% c("Altres comunitats autònomes") ~ 2,
    lloc_naix %in% c("Fora d'Espanya") ~ 5,
    TRUE ~ NA
  ))

## Convert age group to same format as population data
df <- df |>
  mutate(edat_gr = as.numeric(edat_gr))

svydf <- svydesign(ids= ~1, weights= ~1, data=df)

svydf <- rake(design=svydf,
               sample.margins=list(~p_recall, ~llengua_primera, ~estudis_1_3, ~lloc_naix),
               population.margins=list(past_results, pop_llengua, pop_estudis, pop_lloc_naix))

(svytable(~ p_recall, svydf, Ntotal=100))
(svytable(~ llengua_primera, svydf, Ntotal=100))
(svytable(~ estudis_1_3, svydf, Ntotal=100))
(svytable(~ lloc_naix, svydf, Ntotal=100))

## ---------------------------------------- 
## Save weights

weight <- weights(svydf)/mean(weights(svydf)) ## Normalize
recall_weight <- data.frame("id"=df$id, "weight"=weight)
saveRDS(recall_weight, file.path(DTA_FOLDER, "weight.rds"))

## ---------------------------------------- 
## Clean up

stopCluster(cl)
