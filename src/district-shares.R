#!/usr/bin/env Rscript

## Estimates vote share by district 

library(yaml)
library(haven)
library(rstan)

options(mc.cores = parallel::detectCores() - 1)

## ---------------------------------------- 
## Read in data and configuration

config <- read_yaml("./config/config.yaml"); attach(config)
bop <- readRDS(file.path(DTA_FOLDER, "BOP221.RDS"))
p_intention <- readRDS(file.path(DTA_FOLDER, "individual-behavior.RDS"))

## Merge data
bop <- merge(bop, p_intention, by = "id")

bop <- bop[!bop$p_intention %in% c("No.votaria"), ] ## Only interested in vote shares
bop <- droplevels(bop)

## ---------------------------------------- 
## Set priors for vote share in each district

catshare <- prop.table(xtabs(weight ~ p_intention, data=bop))

cfactors <- xtabs(weight ~ provincia + p_intention, data=bop) ## Only to get size and names
cfactors[] <- 1

## Prior for each district is vote share in Catalonia
P <- t(cfactors) * as.vector(catshare) 

#' Calculate beta parameters for given mean and standard deviation
bparams <- function(mu, var) {
  alpha <- ((1 - mu)/var - (1 / mu))*mu^2
  beta <- alpha * (1/mu - 1)
  return(list(alpha=alpha, beta=beta))
}

## The priors for each party and district are a beta centered in the
## vote share and with a fixed variance
priors <- bparams(P, .001)
alpha <- priors$alpha
beta <- priors$beta

## ---------------------------------------- 
## Prepare data to pass to Stan

R <- model.matrix(~ p_intention - 1, data=bop)
D <- model.matrix(~ provincia - 1, data=bop)

## Create matrix of unique combinations of party and district. The
## weight is the sum of the individual weights
data <- cbind(weight=bop$weight, R, D) 
y <- aggregate(weight ~ ., data, sum)

## Data object to pass to Stan
data <- list(results=y[, grepl("intention", names(y))],
             dummies=y[, grepl("provincia", names(y))],
             weights=y[, "weight"],
             a=t(alpha), ## hyper-priors
             b=t(beta),  ## hyper-priors
             D=ncol(D),  ## Number of districts
             P=ncol(R),  ## Number of parties
             N=nrow(y))  ## Number of observations

fit <- stan(file=file.path(SRC_FOLDER, "district-shares.stan"),
            data=data,
            chains=3,
            iter=1500)

## ---------------------------------------- 
## Save estimates in simulation format

pestimates <- extract(fit)

pestimates <- apply(pestimates$beta, c(2, 3), mean)

## Use the dimension names of the factors matrix
pestimates <- as.table(pestimates)
dimnames(pestimates) <- dimnames(cfactors)

## ---------------------------------------- 
## Save data
saveRDS(pestimates, file.path(DTA_FOLDER, "vote-share-district.RDS"))
