#!/usr/bin/env Rscript

## Creates weights that match reported behavior in previous elections
## to electoral results. Non-reports are treated as having abstained.

library(yaml)
library(haven)
library(survey)
library(labelled)
library(dplyr)

## ---------------------------------------- 
## Read in data and configuration

config <- read_yaml("./config/config.yaml")
bop <- readRDS(file.path(config$DTA_FOLDER, "BOP221.RDS"))

## ---------------------------------------- 
## Results of the last election

past_results <- c("PPC"=109067,
                  "ERC"=603607,
                  "PSC"=652858,
                  "C's"=157903,
                  "CUP"=189087,
                  "Catalunya en Comú Podem"=194626,
                  "Junts per Catalunya"=568002,
                  "Vox"=217883,
                  "Altres"=116590 + 24021 + 40966, # Blanc + Nul
                  "No va votar"=2494382)

past_results <- data.frame("recall"=names(past_results),
                           "Freq"=past_results/sum(past_results),
                           row.names=NULL)

## ---------------------------------------- 
## Recode past behavior 

bop$recall <- as_factor(bop$recall)

## Create an "NA" factor
bop$recall <- addNA(bop$recall)
## All nonresponse/don't recall is abstention
levels(bop$recall)[is.na(levels(bop$recall))] <- "No va votar"
levels(bop$recall)[levels(bop$recall) == "No ho sap"] <- "No va votar"
## Data error 
levels(bop$recall)[levels(bop$recall) == "5"] <- "No va votar"

bop$recall <- droplevels(bop$recall)

## ---------------------------------------- 
## Poststratify to past electoral results

svybop <- svydesign(ids= ~1, weights= ~1, data=bop)
svybop <- postStratify(svybop, ~recall, past_results)

(svytable(~ recall, svybop, Ntotal=100))

## ---------------------------------------- 
## Save weights

weight <- weights(svybop)/mean(weights(svybop)) ## Normalize
recall_weight <- data.frame("id"=bop$id, "weight"=weight)
saveRDS(recall_weight, file.path(config$DTA_FOLDER, "weight.RDS"))
