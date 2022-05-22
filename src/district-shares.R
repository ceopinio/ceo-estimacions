#!/usr/bin/env Rscript

## Estimates vote share by district 

library(yaml)
library(haven)
library(rstan)

options(mc.cores = parallel::detectCores() - 1)

## ---------------------------------------- 
## Read in data and configuration

config <- read_yaml("./config/config.yaml")
bop <- readRDS(file.path(config$DTA_FOLDER, "BOP221.RDS"))
p_intention <- readRDS(file.path(config$DTA_FOLDER, "individual-behavior.RDS"))

## Merge data
bop <- merge(bop, p_intention, by = "id")

bop <- bop[!bop$p_intention %in% c("No.votaria"), ]
bop <- droplevels(bop)

## ---------------------------------------- 
## Estimate of district vote shares

common_share <- prop.table(xtabs(weight ~ p_intention, data=bop))

Nparties <- 9
cfactors <- data.frame("Barcelona"=rep(1, Nparties),
                       "Girona"=rep(1, Nparties),
                       "Lleida"=rep(1, Nparties),
                       "Tarragona"=rep(1, Nparties))

P <- cfactors * common_share

eb <- function(mu, var) {
  alpha <- ((1 - mu) / var - 1 / mu) * mu ^ 2
  beta <- alpha * (1 / mu - 1)
  return(params = list(alpha = alpha, beta = beta))
}

alpha <- eb(P, .0001)$alpha
beta <- eb(P, .0001)$beta

## Behavior matrix
R <- model.matrix(~ p_intention - 1, data=bop)
D <- model.matrix(~ provincia - 1, data=bop)

y <- cbind(weight=1:nrow(R), R, D)
y <- aggregate(weight ~ ., y, length)

data <- list(results=y[, grepl("intention", names(y))],
             dummies=y[, grepl("provincia", names(y))],
             weights=y[, "weight"],
             a=t(alpha), ## hyper-priors
             b=t(beta), ## hyper-priors
             D=ncol(D),
             P=ncol(R),
             N=nrow(y))

fit <- stan(file="src/district-shares.stan",
            data=data,
            chains=3,
            iter=1500)

res <- extract(fit)

t(apply(res$beta, c(2, 3), mean))


## ## Save data
## saveRDS(district_share, file.path(config$DTA_FOLDER, "vote-share-district.RDS"))
