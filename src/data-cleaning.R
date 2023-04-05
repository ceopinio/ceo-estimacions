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

list2env(read_yaml("config/config.yaml"), envir=globalenv())
bop <- read_sav(file.path(RAW_DTA_FOLDER, "Microdades anonimitzades 1050.sav"))

## ---------------------------------------- 
## Assign ID to data

bop$id <- 1:nrow(bop)

## ---------------------------------------- 
## Data shuffling
bop <- bop[sample(nrow(bop)),]

## ---------------------------------------- 
## Data cleaning

bop <- bop |>
  mutate(intention = case_when(INT_PARLAMENT_VOT_R %in% ## Vote intention
                                 c(1, 3, 4, 6, 10, 18, 21, 23, 80) ~ INT_PARLAMENT_VOT_R,
                               TRUE ~ NA_real_),
         recall = case_when(REC_PARLAMENT_VOT_R < 93 ~ REC_PARLAMENT_VOT_R, ## Vot ultimes eleccions
                            REC_PARLAMENT_VOT_R %in% c(93, 94) ~ 80, ## "Altres partits" (with "nul" and "en blanc")
                            REC_PARLAMENT_VOT_R > 96 ~ 98), ## Vote recall
         abstention = case_when(INT_PARLAMENT_PART %in% c(1, 2, 4, 5) ~ INT_PARLAMENT_PART,
                                TRUE ~ NA_real_), ## Stated abstention
         simpatia = case_when(SIMPATIA_PARTIT_R %in% c(1, 3, 4, 6, 10, 18, 21, 23, 80, 95) ~ SIMPATIA_PARTIT_R,
                              SIMPATIA_PARTIT_R %in% c(98, 99) ~ NA_real_,
                              TRUE ~ 80), ## Stated proximity
         SIMPATIA_PARTIT_PROPER_R = case_when(SIMPATIA_PARTIT_PROPER %in% c(1, 3, 4, 6, 10, 18, 21, 23, 80, 95) ~ SIMPATIA_PARTIT_PROPER,
                                              is.na(SIMPATIA_PARTIT_PROPER) ~ NA_real_, 
                                              SIMPATIA_PARTIT_PROPER %in% c(98, 99) ~ NA_real_,
                                              TRUE ~ 80), ## No simpatia partit, quin més proximitat
         across(c("IDEOL_0_10", ## Extrema esquerra - extrema dreta
                  "CAT_0_10", ## Mínim catalanisme - màxim catalanisme
                  "ESP_0_10", ## Mínim espanyolisme - màxim espanyolisme
                  "RISCOS"), ~ if_else(.x >= 98,
                                       NA_real_,
                                       as.numeric(.x))), ## Spatial variables
         across(c("EDAT_GR",
                  "RELIGIO_FREQ",
                  "SIT_LAB",
                  "ACTITUD_INDEPENDENCIA",
                  "RELACIONS_CAT_ESP",
                  "SIT_ECO_CAT",
                  "SIT_ECO_CAT_RETROSPECTIVA",
                  "SIT_ECO_CAT_PROSPECTIVA",                                    
                  "SIT_POL_CAT",
                  "SIT_ECO_ESP",
                  "SIT_POL_ESP",
                  "SATIS_DEMOCRACIA",
                  "INTERES_POL_PUBLICS",
                  "INF_POL_DIARI_FREQ",
                  "INF_POL_RADIO_FREQ",                  
                  "INF_POL_TV_FREQ",
                  "INF_POL_XARXES_FREQ",
                  "INF_POL_CONEGUTS_FREQ",
                  "PART_ELECCIONS"), ~ if_else(.x >= 98,
                                               NA_integer_,
                                               as.integer(.x))), ## Categorical variables
         across(starts_with("CONEIX_"), ~ if_else(.x >= 98,
                                                  NA_integer_,
                                                  as.integer(.x))), ## Coneixement liders politics
         across(matches("VAL_[A-Z]{1}_[A-Z]{1,}",
                        perl=TRUE), ~ if_else(.x >= 98,
                                              NA_real_,
                                              as.numeric(.x))), ## Valoracio liders polítics
         across(c("VAL_GOV_CAT", "VAL_GOV_ESP"),
                ~ if_else( .x >= 98, NA_real_, as.numeric(.x))), ## Valoracio governs
         across(c("SIT_ECO_CAT", "SIT_POL_CAT", "SIT_ECO_ESP", "SIT_POL_ESP"),
                ~ case_when(.x %in% c(1, 2) ~ 1,
                            .x == 3 ~ 0,
                            .x %in% c(4, 5) ~ -1,
                            TRUE ~ NA_real_)),
         GENERE=case_when(GENERE %in% c(1, 2) ~ GENERE,
                          TRUE ~ NA_real_),
         RELACIONS_CAT_ESP = case_when( RELACIONS_CAT_ESP %in% c(1, 2, 3, 4) ~  as.numeric(RELACIONS_CAT_ESP),
                                        TRUE ~ NA_real_),    
         RELACIONS_CAT_ESP_1_5 = case_when( RELACIONS_CAT_ESP_1_5 %in% c(1, 2, 3, 4, 5) ~  as.numeric(RELACIONS_CAT_ESP_1_5),
                                            TRUE ~ NA_real_),
         LLENGUA_PRIMERA = case_when(LLENGUA_PRIMERA_1_3 %in% c(1, 2, 80) ~ LLENGUA_PRIMERA_1_3,
                                         TRUE ~ 80),
         estudis_1_5 = case_when(ESTUDIS_1_15 %in% c(1, 2, 3) ~ 1L, ## Less than primary
                                 ESTUDIS_1_15 %in% c(4) ~ 2L, ## Secondary
                                 ESTUDIS_1_15 %in% c(5, 6) ~ 3L, ## High School
                                 ESTUDIS_1_15 %in% c(7, 8, 9) ~ 4L, ## Some College
                                 ESTUDIS_1_15 %in% c(10:15) ~ 5L, ## Above
                                 ESTUDIS_1_15 >= 80 ~ NA_integer_),
         ingressos_1_15 = if_else(is.na(INGRESSOS_1_15), INGRESSOS_15_1, INGRESSOS_1_15),
         ingressos_1_5 = case_when(ingressos_1_15 %in% c(1:5) ~ 1L, ## Less than 1000,
                                   ingressos_1_15 %in% c(6:8) ~ 2L, ## Less than 2000,
                                   ingressos_1_15 %in% c(9:10) ~ 3L, ## Less than 3000
                                   ingressos_1_15 %in% c(11:15) ~ 4L, ## More than 3000
                                   ingressos_1_15 >= 98 ~ NA_integer_)) |>
  select("id",
         "intention",
         "recall",
         "simpatia",
         "abstention",
         # Spatial variables
         "SIMPATIA_PARTIT_PROPER_R",
         "IDEOL_0_10",
         "CAT_0_10",
         "ESP_0_10",
         "RISCOS",
         # Categorical variables
         "GENERE",
         "EDAT_GR",
         "RELIGIO_FREQ",
         "SIT_LAB",
         "VAL_GOV_CAT", 
         "VAL_GOV_ESP",
         "ACTITUD_INDEPENDENCIA",
         "RELACIONS_CAT_ESP",
         "RELACIONS_CAT_ESP_1_5",
         "LLENGUA_PRIMERA",
         "SIT_ECO_CAT",
         "SIT_ECO_CAT_RETROSPECTIVA",
         "SIT_ECO_CAT_PROSPECTIVA",                                    
         "SIT_POL_CAT",
         "SIT_ECO_ESP",
         "SIT_POL_ESP",
         "SATIS_DEMOCRACIA",
         "INTERES_POL_PUBLICS",
         "INF_POL_DIARI_FREQ",
         "INF_POL_RADIO_FREQ",                  
         "INF_POL_TV_FREQ",
         "INF_POL_XARXES_FREQ",
         "INF_POL_CONEGUTS_FREQ",
         "PART_ELECCIONS",
         "estudis_1_5",
         "ingressos_1_5",
         "PROVINCIA",
         "HABITAT",
         # Knowledge and evaluation
         starts_with("CONEIX_"),
         matches("VAL_[A-Z]{1}_[A-Z]{1,}", perl=TRUE)) |>
  mutate(across(-matches("0_10|VAL_[A-Z]{1}_[A-Z]{1,}",
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

bop <- droplevels(bop)

## ---------------------------------------- 
## Save data
saveRDS(bop, file.path(DTA_FOLDER, "clean-bop.RDS"))
