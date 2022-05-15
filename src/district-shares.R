#!/usr/bin/env Rscript

## Estimates vote share by district 

library(yaml)
library(haven)

## ---------------------------------------- 
## Read in data and configuration

config <- read_yaml("./config/config.yaml"); attach(config)
bop <- readRDS(file.path(DTA_FOLDER, "BOP221.RDS"))
p_intention <- readRDS(file.path(DTA_FOLDER, "individual-behavior.RDS"))

## Merge data
bop <- merge(bop, p_intention, by = "id")

## ---------------------------------------- 
## Estimate of district vote shares
district_share <- prop.table(xtabs(weight ~ provincia + p_intention, data=bop), 1)

## Save data
saveRDS(district_share, file.path(DTA_FOLDER, "vote-share-district.RDS"))
