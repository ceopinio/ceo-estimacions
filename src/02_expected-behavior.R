## Description: Estimation of individual behavior
## Author: Gonzalo Rivero
## Date: 07-Apr-2022 20:04

source("./setup.R")

set.seed(314965)

library(haven)
library(labelled)
library(dplyr)
library(caret); library(xgboost)
library(stringi)
library(pROC)

bop <- read_dta(file.path(RAW_DTA_FOLDER, "./BOP221.dta"))

## Recoding for model
bop <- bop |>
  mutate(intention=case_when(INT_PARLAMENT_VOT_R < 93 ~ INT_PARLAMENT_VOT_R,
                             INT_PARLAMENT_VOT_R == 93 ~ 80, # Null is other
                             INT_PARLAMENT_VOT_R > 93 ~ NA_real_),
         recall=case_when(REC_PARLAMENT_VOT_R < 93 ~ REC_PARLAMENT_VOT_R,
                          REC_PARLAMENT_VOT_R %in% c(93, 94)~ 80, ## Null are other
                          REC_PARLAMENT_VOT_R > 96 ~ 98), ## Vote recall
         abstention=case_when(INT_PARLAMENT_VOT_R %in% 96 ~ "Will.not.vote",
                              INT_PARLAMENT_VOT_R %in% c(98, 99) ~ NA_character_,
                              TRUE ~ "Will.vote"), ## Stated abstention
         simpatia=case_when(SIMPATIA_PARTIT_R < 93 ~ SIMPATIA_PARTIT_R,
                            SIMPATIA_PARTIT_R > 94 ~ NA_real_), ## Stated proximity
         across(c("IDEOL_0_10",
                  "CAT_0_10",
                  "ESP_0_10",
                  "CONFI_PARTITS",
                  "CONFI_UE"), ~ if_else(.x >= 98, NA_real_, as.numeric(.x))), ## Spatial variables
         across(c("GENERE",
                  "EDAT_GR",
                  "ESTUDIS_1_15",
                  "RELIGIO_FREQ",
                  "INGRESSOS_1_15",
                  "SIT_LAB",
                  "ACTITUD_INDEPENDENCIA",
                  "MONARQUIA_REPUBLICA",
                  "VOT_DRET_DEURE",
                  "LLENGUA_PRIMERA",
                  "SIT_ECO_CAT",
                  "SIT_POL_CAT",
                  "SATIS_DEMOCRACIA",
                  "INF_POL_TV_FREQ",
                  "INF_POL_XARXES_FREQ"), ~ if_else(.x >= 98,
                                              NA_integer_,
                                              as.integer(.x))), ## Categorical variables
         across(starts_with("CONEIX_"), ~ if_else(.x >= 98,
                                                  NA_integer_,
                                                  as.integer(.x))), ## Knowledge
         across(matches("VAL_[A-Z]{1}_[A-Z]{1,}",
                        perl=TRUE), ~ if_else(.x >= 98,
                                              NA_real_,
                                              as.numeric(.x)))) |> ## Evaluation
  select("intention",
         "recall",
         "simpatia",
         "abstention",
         # Spatial variables
         "IDEOL_0_10",
         "CAT_0_10",
         "ESP_0_10",
         "CONFI_PARTITS",
         "CONFI_UE",
         # Categorical variables
         "GENERE",
         "EDAT_GR",
         "ESTUDIS_1_15",
         "RELIGIO_FREQ",
         "INGRESSOS_1_15",
         "SIT_LAB",
         "ACTITUD_INDEPENDENCIA",
         "MONARQUIA_REPUBLICA",
         "VOT_DRET_DEURE",         
         "LLENGUA_PRIMERA",
         "SIT_ECO_CAT",
         "SIT_POL_CAT",
         "SATIS_DEMOCRACIA",
         "INF_POL_TV_FREQ",
         "INF_POL_XARXES_FREQ",
         # Knowledge and evaluation
         starts_with("CONEIX_"),
         matches("VAL_[A-Z]{1}_[A-Z]{1,}", perl=TRUE)) |>
  mutate(across(-matches("0_10|VAL_[A-Z]{1}_[A-Z]{1,}|CONFI_",
                         perl=TRUE), ~ as_factor(.))) |> ## Most vars are factors
  rename_with(tolower)

levels(bop$intention) <- stri_trans_general(levels(bop$intention), "latin-ascii")
levels(bop$intention) <- stri_replace_all_charclass(levels(bop$intention), "[[:punct:]]", "")
levels(bop$intention) <- stri_replace_all_charclass(levels(bop$intention), "[[:whitespace:]]", ".")

## Parameter search
grid_partychoice <- expand.grid(eta=c(.01),
                                max_depth=c(1),
                                min_child_weight=1,
                                subsample=0.8,
                                colsample_bytree=0.8,
                                nrounds=c(1)*100,
                                gamma=0)

control_partychoice <- trainControl(method="repeatedcv",
                                    number=5,
                                    repeats=1,
                                    classProbs=TRUE,                            
                                    summaryFunction=multiClassSummary)

fit_partychoice <- train(as.factor(intention) ~ .,
                         data=droplevels(subset(bop, subset=!is.na(bop$intention), select= -abstention)), 
                         method="xgbTree", 
                         trControl=control_partychoice,
                         tuneGrid=grid_partychoice,
                         na.action=na.pass,
                         verbose=FALSE,
                         verbosity=0)

m <- xgb.Booster.complete(fit_partychoice$finalModel, saveraw=FALSE)
xgb.save(m, fname=assetize("fit_partychoice.model"))
saveRDS(fit_partychoice, assetize("fit_partychoice.RDS"))

partychoice <- predict(fit_partychoice, newdata=bop, na.action=na.pass, type="prob")
bop$pintention <- predict(fit_partychoice, newdata=bop, na.action=na.pass, type="raw")

## Vote or not
grid_abstention <- expand.grid(eta=c(.01, .005, .001),
                               max_depth=c(1, 2, 3),
                               min_child_weight=1,
                               subsample=0.8,
                               colsample_bytree=0.8,
                               nrounds=c(1, 3, 5, 7, 10)*100,
                               gamma=0)

control_abstention <- trainControl(method="repeatedcv",
                                   number=5,
                                   repeats=1,
                                   classProbs=TRUE,
                                   summaryFunction=multiClassSummary,
                                   savePredictions=TRUE)

fit_abstention <- train(as.factor(abstention) ~ .,
                        data=droplevels(subset(bop, subset=!is.na(bop$abstention), select= -intention)), 
                        method="xgbTree", 
                        trControl=control_abstention,
                        tuneGrid=grid_abstention,
                        na.action=na.pass,
                        verbose=FALSE,
                        verbosity=0)

m <- xgb.Booster.complete(fit_abstention$finalModel, saveraw=FALSE)
xgb.save(m, fname=assetize("fit_abstention.model"))
saveRDS(fit_abstention, assetize("fit_abstention.RDS"))


## Read back
mfit <- readRDS(assetize("fit_abstention.RDS"))
m <- xgb.load(assetize("fit_abstention.model"))
mfit$finalModel$handle <- m$handle
mfit$finalModel$raw <- m$raw


## abstention <- predict(fit_abstention, newdata=bop, na.action=na.pass, type="prob")
## bop$pabstention <- predict(fit_abstention, newdata=bop, na.action=na.pass, type="raw")

## ## Participation calibration
## cal_abstention <- calibration(obs ~ Will.vote, data = fit_abstention$pred)

## ## Participation threshold
## probs <- seq(.1, .9, by = 0.02)
## ths <- thresholder(fit_abstention,
##                    threshold=probs,
##                    final=TRUE,
##                    statistics="all")

## in_sample_pabstention <- predict(fit_abstention,
##                                  newdata=subset(bop, subset=!is.na(bop$abstention)),
##                                  na.action=na.pass,
##                                  type="prob")
## roc <- roc(with(subset(bop, subset=!is.na(bop$abstention)), abstention),
##            in_sample_pabstention$"Will.not.vote")

## ## Consolidate results
## bop$eintention <- bop$intention
## bop$eintention[is.na(bop$intention)] <- bop$pintention[is.na(bop$intention)]
## bop$eintention[bop$abstention == "Will.not.vote"] <- "No.votaria"
## bop$eintention[abstention$"Will.vote" < (1 - 0.224)] <- "No.votaria"

## ## Estimates
## prop.table(table(bop$eintention != "No.votaria"))*100
## prop.table(table(bop$eintention[bop$eintention!="No.votaria"]))*100

## Lo más probable es que los que participen en la encuesta sean mas
## proclives a votar asi que nos interesa estimar la distribucion de
## voto condicional a participacion. Esto es, no queremos (no podemos)
## estimar los abstencionistas usando estos datos sin más. 

## Por algún motivo, el modelo de abstención penaliza mucho al PSC
## (tienen probabilidades altas de aparecer como no si no votasen)

## Many people from PSC not in sample (12% recall vs real 23% )
