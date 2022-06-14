#!/usr/bin/env Rscript

## Reads in raw data (from RAW_DTA_FOLDER, in .dta format) and creates
## clean version (to DTA_FOLDER, in .RDS format) that is used in the
## rest of the scripts.

library(yaml)
library(haven)
library(labelled)
library(dplyr)
library(stringi)

## ---------------------------------------- 
## Read in data and configuration

config <- read_yaml("config/config.yaml"); attach(config)
bop <- read_dta(file.path(RAW_DTA_FOLDER, "BOP221.dta"))

## ---------------------------------------- 
## Assign ID to data

bop$id <- 1:nrow(bop)
  
## ---------------------------------------- 
## Data cleaning

bop <- bop |>
  mutate(intention=case_when(INT_PARLAMENT_VOT %in%
                               c(1, 3, 4, 6, 10, 21, 22, 23) ~ INT_PARLAMENT_VOT,
                             INT_PARLAMENT_VOT %in%
                               c(5, 19, 20) ~ 80,
                             INT_PARLAMENT_VOT_R > 80 ~ NA_real_),
         recall=case_when(REC_PARLAMENT_VOT_R < 93 ~ REC_PARLAMENT_VOT_R,
                          REC_PARLAMENT_VOT_R %in% c(93, 94) ~ 80, ## Null are other
                          REC_PARLAMENT_VOT_R > 96 ~ 98), ## Vote recall
         abstention=case_when(INT_PARLAMENT_VOT %in% 96 ~ "Will.not.vote",
                              INT_PARLAMENT_VOT %in% c(98, 99) ~ NA_character_,
                              TRUE ~ "Will.vote"), ## Stated abstention
         simpatia=case_when(SIMPATIA_PARTIT_R < 93 ~ SIMPATIA_PARTIT_R,
                            SIMPATIA_PARTIT_R > 94 ~ NA_real_), ## Stated proximity
         across(c("IDEOL_0_10",
                  "CAT_0_10",
                  "ESP_0_10",
                  "CONFI_PARTITS",
                  "CONFI_UE",
                  "CONFI_GOV_CAT",
                  "CONFI_GOV_ESP"), ~ if_else(.x >= 98,
                                         NA_real_,
                                         as.numeric(.x))), ## Spatial variables
         across(c("GENERE",
                  "EDAT_GR",
                  "RELIGIO_FREQ",
                  "SIT_LAB",
                  "ACTITUD_INDEPENDENCIA",
                  "ACTITUD_AUTORITAT",                  
                  "RELACIONS_CAT_ESP",
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
                                              as.numeric(.x))), ## Evaluation
         estudis_1_5=case_when(ESTUDIS_1_15 %in% c(1, 2, 3) ~ 1L, # Less than primary
                               ESTUDIS_1_15 %in% c(4) ~ 2L, # Secondary
                               ESTUDIS_1_15 %in% c(5, 6) ~ 3L, # High School
                               ESTUDIS_1_15 %in% c(7, 8, 9) ~ 4L, ## Some College
                               ESTUDIS_1_15 %in% c(10:80) ~ 5L, ## Above
                               ESTUDIS_1_15 >= 98 ~ NA_integer_),
         ingressos_1_5=case_when(INGRESSOS_1_15 %in% c(1:5) ~ 1L, ## Less than 1000,
                                 INGRESSOS_1_15 %in% c(6:8) ~ 2L, ## Less than 2000,
                                 INGRESSOS_1_15 %in% c(9:10) ~ 3L, ## Less than 3000
                                 INGRESSOS_1_15 %in% c(11:15) ~ 4L, ## More than 3000
                                 INGRESSOS_1_15 >= 98 ~ NA_integer_)) |>
  select("id",
         "intention",
         "recall",
         "simpatia",
         "abstention",
         # Spatial variables
         "IDEOL_0_10",
         "CAT_0_10",
         "ESP_0_10",
         "CONFI_PARTITS",
         "CONFI_UE",
         "CONFI_GOV_CAT",
         "CONFI_GOV_ESP",
         # Categorical variables
         "GENERE",
         "EDAT_GR",
         "estudis_1_5",
         "RELIGIO_FREQ",
         "ingressos_1_5",
         "SIT_LAB",
         "ACTITUD_INDEPENDENCIA",
         "ACTITUD_AUTORITAT",         
         "RELACIONS_CAT_ESP",
         "MONARQUIA_REPUBLICA",
         "VOT_DRET_DEURE",         
         "LLENGUA_PRIMERA",
         "SIT_ECO_CAT",
         "SIT_POL_CAT",
         "SATIS_DEMOCRACIA",
         "INF_POL_TV_FREQ",
         "INF_POL_XARXES_FREQ",
         "PROVINCIA",
         "HABITAT",
         # Knowledge and evaluation
         starts_with("CONEIX_"),
         matches("VAL_[A-Z]{1}_[A-Z]{1,}", perl=TRUE)) |>
  mutate(across(-matches("0_10|VAL_[A-Z]{1}_[A-Z]{1,}|CONFI_",
                         perl=TRUE), ~ as_factor(.))) |> ## Most vars are factors
  rename_with(tolower) ## Work with namevars in lowercase

## ---------------------------------------- 
## Clean up party names

clean_party_name <- function(x) {
  if (!is.factor(x)) {
    stop("Party variable is expected to be a factor")
  }

  levels(x) <- stri_trans_general(levels(x), "latin-ascii") 
  levels(x) <- stri_replace_all_charclass(levels(x), "[[:punct:]]", "")
  levels(x) <- stri_replace_all_charclass(levels(x), "[[:whitespace:]]", ".")
  return(x)
}

bop$intention <- clean_party_name(bop$intention)
bop$recall <- clean_party_name(bop$recall)

## ---------------------------------------- 
## Save data
saveRDS(bop, file.path(DTA_FOLDER, "BOP221.RDS"))
