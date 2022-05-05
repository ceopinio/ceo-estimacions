#!/usr/bin/env Rscript

## Estimates vote shares using predictions of behavior at the
## individual level (party choice and abstention). Party choice
## predictions are only applied to individuals who do not report
## intended behavior. Absention predictions are applied based on the
## optimal cutoff. Estimates are weighed to electoral results of the
## previous election.

library(yaml)
library(tidyr)
library(ggplot2); theme_set(theme_bw())

## ---------------------------------------- 
## Read in data and configuratio

config <- read_yaml("./config/config.yaml")
bop <- readRDS(file.path(config$DTA_FOLDER, "BOP221.RDS"))

## Recall weights
recall_weights <- readRDS(file.path(config$DTA_FOLDER, "weight.RDS"))

## Predicted behavior
p_partychoice <- readRDS(file.path(config$DTA_FOLDER, "predicted-partychoice.RDS"))
p_abstention <- readRDS(file.path(config$DTA_FOLDER, "predicted-abstention.RDS"))
thr_abstention <- readRDS(file.path(config$DTA_FOLDER, "thr-predicted-abstention.RDS"))

## Join all results
bop <- merge(bop, recall_weights, by="id") 
bop <- merge(bop, p_partychoice, by="id")
bop <- merge(bop, p_abstention, by="id") ## Probability of *not* voting

## ---------------------------------------- 
## Consolidate results

## Predicted behavior defaults to reported behavior
bop$p_intention <- bop$intention
## If they did not report a party choice, assign the predicted 
bop$p_intention[is.na(bop$intention)] <- bop$p_partychoice[is.na(bop$intention)]
## If they declare they will not vote, use that behavior
bop$p_intention[bop$abstention == "Will.not.vote"] <- "No.votaria"
## Assign to abstention all respondents with low predicted probability
## of voting (relative to cutoff)
bop$p_intention[bop$p_abstention > (1 - thr_abstention)] <- "No.votaria"
bop$p_intention <- droplevels(bop$p_intention)

## Save results 
saveRDS(data.frame("id"=bop$id,
                   "p_intention"=bop$p_intention,
                   "weight"=bop$weight),
        file.path(config$DTA_FOLDER, "individual-behavior.RDS"))

## ---------------------------------------- 
## Estimated vote shares

## Unweighted estimates
estimates <- prop.table(xtabs(~ p_intention, data=bop))*100
estimates <- as.data.frame(estimates)
names(estimates)[names(estimates) == "Freq"] <- "unweighted"

## Weighted estimates
westimates <- prop.table(xtabs(weight ~ p_intention, data=bop))*100
westimates <- as.data.frame(westimates)
names(westimates)[names(westimates) == "Freq"] <- "weighted"

## Join 
estimates <- merge(estimates, westimates, by="p_intention")
names(estimates)[names(estimates) == "p_intention"] <- "party"

## Save data
saveRDS(estimates, file.path(config$DTA_FOLDER, "estimated-vote-share.RDS"))

## ---------------------------------------- 
## Simulated effect of turnout rates

turnout <- seq(.5, 1, by=0.01)
n_abstention <- (1 - turnout) *
  (nrow(bop) - sum(bop$abstention == "Will.not.vote", na.rm=TRUE))

vote <- bop$intention
vote[is.na(bop$intention)] <- bop$p_partychoice[is.na(bop$intention)]
vote <- rep(list(as.character(vote)), length(turnout))

## Predicted as abstainers
pabstainers <- lapply(round(n_abstention), \(x) order(bop$p_abstention)[1:x])
## Declared as abstainers
dabstainers <- rep(list(which(bop$abstention == "Will.not.vote")), length(turnout))
abstainers <- mapply(function(x, y) c(x, y), x=pabstainers, y=dabstainers)

for (i in seq_along(turnout)) vote[[i]][abstainers[[i]]] <- "No.votaria"

sim <- as.data.frame(sapply(vote, \(x) prop.table(xtabs(bop$weight ~ x, subset=x != "No.votaria"))))
eturnout <- sapply(vote, \(x) prop.table(xtabs(bop$weight ~ x == "No.votaria"))["TRUE"]) ## Actual turnout

names(sim) <- paste0("p", turnout*100)
sim$party <- rownames(sim)

sim <- reshape(sim,
               varying=1:length(turnout),
               direction="long",
               v.names="share",
               timevar="p")

sim$ep <- rep(eturnout, each=9)

## Because we are keeping everyone who declared to abstain with their
## reported choice, the maximum turnout is the declared turnout
p <- ggplot(sim, aes(x= 1 - ep, y=share, group=party, colour=party))
pq <- p + geom_line() +
  labs(title="Effect of simulated turnout on vote share",
       x="Turnout rate",
       y="Vote share") +
  scale_color_discrete("Party")
 
ggsave(file.path(config$IMG_FOLDER, "simulation-abstention.pdf"), pq)
