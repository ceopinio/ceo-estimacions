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
df <- readRDS(file.path(DTA_FOLDER, "clean-df.RDS"))

p_intention <- readRDS(file.path(DTA_FOLDER, "individual-behavior.RDS"))

past_results <- readr::read_delim(file.path(RAW_DTA_FOLDER, "results-2021.csv"),  delim = ";", escape_double = FALSE, trim_ws = TRUE)

## Merge data
df <- merge(df, p_intention, by = "id")

df <- df[!df$p_intention %in% c("No.votaria"), ] ## Only interested in vote shares
df <- droplevels(df)

## ---------------------------------------- 
## Set priors for vote share in each district

## Calculate relation between results in district and results in Catalonia
sresults <- prop.table(xtabs(weight ~ p_intention, data=df))

## Shares in previous election
results <- past_results |>
  filter(code != 8000) |>
  mutate(code=case_when(code %in% c(93, 94, 80) ~ #Nul, Blanc, Altres
                          80,
                        code == 22 ~ 18,
                        TRUE ~ code),
         code=factor(code, levels(df$p_intention))) |>
  group_by(provincia, code) |>
  summarize(votes=sum(votes)) |>
  ungroup() |>
  as.data.frame()

## We add a non-informative prior for Aliança Catalana, because it is a new party
## Just like if they had a 2% of the valid votes in each district
results_AC <- results |>
  summarise(total = sum(votes), .by = provincia) |>
  mutate(code = 25, votes = round(total*0.02)) |>
  select(-total)

results <- rbind(results, results_AC)
results$code <- factor(results$code)

results <- xtabs(votes ~ provincia + code, data=results)
catshare <- prop.table(colSums(results)) ## Catalonia results
provshares <- prop.table(results, 1) ## District results 
cfactors <- apply(provshares, 1, \(x) x/catshare) ## Correction factor

## Prior for each district is vote share relative to observed survey results in Catalonia
P <- apply(cfactors, 2, \(x) x*sresults/sum(x*sresults))

## model
fit <- dshare(p_intention ~ provincia,
              weights=weight,
              data=df,
              priors=P,
              sd=.025, # This sets the importance of the priors (higher sd, less informative priors)
              chains=3,
              iter=2000) # If no convergence, increase iterations

## ---------------------------------------- 
## Save estimates in simulation format

pestimates <- rstan::extract(fit)
pestimates <- apply(pestimates$beta, c(2, 3), mean)

## Use the dimension names of the factors matrix
dimnames(pestimates) <- dimnames(t(cfactors))

## ---------------------------------------- 
## Save data
saveRDS(pestimates, file.path(DTA_FOLDER, "vote-share-district.RDS"))
