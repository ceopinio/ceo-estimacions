#!/usr/bin/env Rscript

## Estimates vote share by district by combining the small samples
## from each district with priors coming from past elections (the
## deviation of each district relative to Catalonia from the past
## elections applied to the survey estimates)

library(yaml)
library(haven)
library(dplyr)
library(rstan)
library(dshare)

options(mc.cores = parallel::detectCores() - 1)

## ---------------------------------------- 
## Read in data and configuration

list2env(read_yaml("./config/config.yaml"), envir=globalenv())
bop <- readRDS(file.path(DTA_FOLDER, "clean-bop.RDS"))

p_intention <- readRDS(file.path(DTA_FOLDER, "individual-behavior.RDS"))

past_results <- read.csv2(file.path(RAW_DTA_FOLDER, "results-2019.csv"))

## Merge data
bop <- merge(bop, p_intention, by = "id")

bop <- bop[!bop$p_intention %in% c("No.votaria"), ] ## Only interested in vote shares
bop <- droplevels(bop)

## ---------------------------------------- 
## Set priors for vote share in each district

## Calculate relation between results in district and results in Catalonia
sresults <- prop.table(xtabs(weight ~ p_intention, data=bop))

## Some parties may have changed names between the two elections
## Catalunya En Comu Podem -> En Comu Podem
past_results[past_results$party == "Catalunya.en.Comu.Podem", "party"] <- "En.Comu.Podem"

## Shares in previous election
results <- past_results |>
  filter(party != "Censo") |>
  mutate(party=case_when(party %in% c("Nul", "Blanc", "Altres.partits") ~
                           "Altres",
                         TRUE ~ party),
         party=factor(party, levels(bop$p_intention))) |>
  group_by(provincia, party) |>
  summarize(votes=sum(votes)) |>
  as.data.frame()

results <- xtabs(votes ~ provincia + party, data=results)
catshare <- prop.table(colSums(results)) ## Catalonia results
provshares <- prop.table(results, 1) ## District results
cfactors <- apply(provshares, 1, \(x) x/catshare) ## Correction factor

## Prior for each district is vote share relative to observed survey results in Catalonia
P <- apply(cfactors, 2, \(x) x*sresults/sum(x*sresults))

## model
fit <- dshare(p_intention ~ provincia,
              weights=weight,
              data=bop,
              priors=P,
              sd=.025,
              chains=3)

## ---------------------------------------- 
## Save estimates in simulation format

pestimates <- rstan::extract(fit)
pestimates <- apply(pestimates$beta, c(2, 3), mean)

## Use the dimension names of the factors matrix
dimnames(pestimates) <- dimnames(t(cfactors))

## ---------------------------------------- 
## Save data
saveRDS(pestimates, file.path(DTA_FOLDER, "vote-share-district.RDS"))

