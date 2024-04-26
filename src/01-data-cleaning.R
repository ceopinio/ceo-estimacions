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
# Need to have the data downloaded from the CEO website and saved in the RAW_DTA_FOLDER
# If not, CEOdata function from the CEOdata R library can be used, 
df <- read_sav(file.path(RAW_DTA_FOLDER, "Microdades_anonimitzades.sav"))

## ---------------------------------------- 
## Assign ID to data

df$id <- 1:nrow(df)

## ---------------------------------------- 
## Data shuffling
df <- df[sample(nrow(df)),]

## ---------------------------------------- 
## Data cleaning

df <- df |>
  mutate(intention = case_when(INT_PARLAMENT_VOT %in% ## Vote intention
                                 c(1, 3, 4, 6, 10, 18, 21, 23, 25, 80) ~ INT_PARLAMENT_VOT,
                               INT_PARLAMENT_VOT == 12 ~ 18,
                               INT_PARLAMENT_VOT %in% c(19, 20) ~ 80,
                               TRUE ~ NA_real_),
         recall = case_when(REC_PARLAMENT_VOT_R < 93 ~ REC_PARLAMENT_VOT_R, ## Vot ultimes eleccions
                            REC_PARLAMENT_VOT_R %in% c(93, 94) ~ 80, ## "Altres partits" (with "nul" and "en blanc")
                            REC_PARLAMENT_VOT_R > 96 ~ 98), ## Vote recall
         abstention = case_when(INT_PARLAMENT_PART_1_4 %in% c(1, 2, 3, 4) ~ INT_PARLAMENT_PART_1_4,
                                TRUE ~ NA_real_), ## Stated abstention
         simpatia = case_when(SIMPATIA_PARTIT %in% c(1, 3, 4, 10, 18, 21, 23, 25, 80, 95) ~ SIMPATIA_PARTIT,
                              SIMPATIA_PARTIT %in% c(12, 24) ~ 18, # Small number of people, added to the "18" category for similarity
                              SIMPATIA_PARTIT %in% c(2, 6, 19) ~ 80, # We put small parties here, at first, to have all categories in a test-train split
                              SIMPATIA_PARTIT %in% c(98, 99) ~ NA_real_,
                              TRUE ~ 80), ## Stated proximity
         SIMPATIA_PARTIT_PROPER = case_when(SIMPATIA_PARTIT_PROPER %in% c(1, 3, 4, 6, 10, 18, 21, 23, 25, 80, 95) ~ SIMPATIA_PARTIT_PROPER,
                                            SIMPATIA_PARTIT_PROPER %in% c(12, 24) ~ 18,
                                              SIMPATIA_PARTIT_PROPER %in% c(19, 20) ~ 80, 
                                              is.na(SIMPATIA_PARTIT_PROPER) ~ NA_real_, 
                                              SIMPATIA_PARTIT_PROPER %in% c(98, 99) ~ NA_real_,
                                              TRUE ~ 80), ## No simpatia partit, quin més proximitat
         across(c("CAT_0_10", ## Mínim catalanisme - màxim catalanisme 
                  "ESP_0_10", ## Mínim espanyolisme - màxim espanyolisme
                  "RISCOS",
                  "VAL_GOV_CAT",
                  "VAL_GOV_ESP",
                  "ESTUDIS_1_6",
                  starts_with("PRE_PARLAMENT_")), ~ if_else(.x >= 98,
                                       NA_real_,
                                       as.numeric(.x))), ## Numeric variables
         across(c("EDAT_GR",
                  "ACTITUD_INDEPENDENCIA",
                  "INTERES_POL",
                  "IDEOL_1_7",
                  "INTERES_PRE_CAMPANYA_PARLAMENT",
                  ), ~ if_else(.x >= 98,
                                               NA_integer_,
                                               as.integer(.x))), ## Categorical variables
         across(starts_with("CONEIX_"), ~ if_else(.x >= 98,
                                                  NA_integer_,
                                                  as.integer(.x))), ## Coneixement liders politics
         across(matches("VAL_[A-Z]{1}_[A-Z]{1,}",
                        perl=TRUE), ~ if_else(.x >= 98,
                                              NA_real_,
                                              as.numeric(.x))), ## Valoracio liders polítics
         across(c("INF_POL_OBJ_DATA_COMICIS"),
                ~ case_when(.x == 1 ~ 1,
                            .x == 2 ~ 0,
                            .x == 3 ~ -1,
                            TRUE ~ NA_real_)),
         LLENGUA_PRIMERA = case_when(LLENGUA_PRIMERA_1_3 %in% c(1, 2, 80) ~ LLENGUA_PRIMERA_1_3,
                                     TRUE ~ NA_real_),
         # Create dicotomical variables for the doubt about the vote intention
         doubting_p1 = case_when(
           INT_PARLAMENT_DUBTE_1 == 1 | INT_PARLAMENT_DUBTE_2 == 1 | INT_PARLAMENT_DUBTE_3 == 1 | INT_PARLAMENT_DUBTE_4 == 1 ~ 1,
           is.na(INT_PARLAMENT_DUBTE_1) ~ NA,
           TRUE ~ 0),
         doubting_p3 = case_when(
           INT_PARLAMENT_DUBTE_1 == 3 | INT_PARLAMENT_DUBTE_2 == 3 | INT_PARLAMENT_DUBTE_3 == 3 | INT_PARLAMENT_DUBTE_4 == 3 ~ 1,
           is.na(INT_PARLAMENT_DUBTE_1) ~ NA,
           TRUE ~ 0),
         doubting_p4 = case_when(
           INT_PARLAMENT_DUBTE_1 == 4 | INT_PARLAMENT_DUBTE_2 == 4 | INT_PARLAMENT_DUBTE_3 == 4 | INT_PARLAMENT_DUBTE_4 == 4 ~ 1,
           is.na(INT_PARLAMENT_DUBTE_1) ~ NA,
           TRUE ~ 0),
         doubting_p6 = case_when(
           INT_PARLAMENT_DUBTE_1 == 6 | INT_PARLAMENT_DUBTE_2 == 6 | INT_PARLAMENT_DUBTE_3 == 6 | INT_PARLAMENT_DUBTE_4 == 6 ~ 1,
           is.na(INT_PARLAMENT_DUBTE_1) ~ NA,
           TRUE ~ 0),
         doubting_p10 = case_when(
           INT_PARLAMENT_DUBTE_1 == 10 | INT_PARLAMENT_DUBTE_2 == 10 | INT_PARLAMENT_DUBTE_3 == 10 | INT_PARLAMENT_DUBTE_4 == 10 ~ 1,
           is.na(INT_PARLAMENT_DUBTE_1) ~ NA,
           TRUE ~ 0),
         doubting_p18 = case_when(
           INT_PARLAMENT_DUBTE_1 == 18 | INT_PARLAMENT_DUBTE_2 == 18 | INT_PARLAMENT_DUBTE_3 == 18 | INT_PARLAMENT_DUBTE_4 == 18 ~ 1,
           is.na(INT_PARLAMENT_DUBTE_1) ~ NA,
           TRUE ~ 0),
         doubting_p21 = case_when(
           INT_PARLAMENT_DUBTE_1 == 21 | INT_PARLAMENT_DUBTE_2 == 21 | INT_PARLAMENT_DUBTE_3 == 21 | INT_PARLAMENT_DUBTE_4 == 21 ~ 1,
           is.na(INT_PARLAMENT_DUBTE_1) ~ NA,
           TRUE ~ 0),
         doubting_p23 = case_when(
           INT_PARLAMENT_DUBTE_1 == 23 | INT_PARLAMENT_DUBTE_2 == 23 | INT_PARLAMENT_DUBTE_3 == 23 | INT_PARLAMENT_DUBTE_4 == 23 ~ 1,
           is.na(INT_PARLAMENT_DUBTE_1) ~ NA,
           TRUE ~ 0),
         doubting_p25 = case_when(
           INT_PARLAMENT_DUBTE_1 == 25 | INT_PARLAMENT_DUBTE_2 == 25 | INT_PARLAMENT_DUBTE_3 == 25 | INT_PARLAMENT_DUBTE_4 == 25 ~ 1,
           is.na(INT_PARLAMENT_DUBTE_1) ~ NA,
           TRUE ~ 0
         )) |>
  select("id",
         "intention",
         "recall",
         "simpatia",
         "abstention",
         "SIMPATIA_PARTIT_PROPER",
         starts_with("doubting_"),
         # Numerical variables
         "CAT_0_10", 
         "ESP_0_10", 
         "RISCOS",
         "VAL_GOV_CAT",
         "VAL_GOV_ESP",
         "ESTUDIS_1_6",
         starts_with("PRE_PARLAMENT_"),
         # Categorical variables
         "EDAT_GR",
         "ACTITUD_INDEPENDENCIA",
         "INTERES_POL",
         "IDEOL_1_7",
         "INTERES_PRE_CAMPANYA_PARLAMENT",
         "INF_POL_OBJ_DATA_COMICIS",
         "LLENGUA_PRIMERA",
         "PROVINCIA",
         "HABITAT",
         "SEXE",
         "LLOC_NAIX",
         # Knowledge and evaluation
         starts_with("CONEIX_"),
         matches("VAL_[A-Z]{1}_[A-Z]{1,}", perl=TRUE)) |>
  mutate(across(-c(matches("0_10|VAL_[A-Z]{1}_[A-Z]{1,}", perl=TRUE), "RISCOS", "VAL_GOV_CAT", "VAL_GOV_ESP",
                   "LLENGUA_PRIMERA", "intention", "recall", "simpatia", "abstention", "SIMPATIA_PARTIT_PROPER",
                   starts_with("PRE_PARLAMENT_"), "SEXE", starts_with("CONEIX_")), 
                ~ as_factor(.))) |> ## Most vars are factors
  mutate(across(c("LLENGUA_PRIMERA", "intention", "recall", "simpatia", "abstention", "SIMPATIA_PARTIT_PROPER"),
                ~ as.factor(.))) |> ## mantenim codis com a factor per no treballar amb etiquetes dels partits
  rename_with(tolower)  ## Work with namevars in lowercase

df <- droplevels(df)

## ---------------------------------------- 
## Save data
saveRDS(df, file.path(DTA_FOLDER, "clean-df.RDS"))
## ---------------------------------------- 
## Save data
saveRDS(bop, file.path(DTA_FOLDER, "clean-bop.RDS"))
