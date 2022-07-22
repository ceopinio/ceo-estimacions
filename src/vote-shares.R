#!/usr/bin/env Rscript

## Estimates vote shares using predictions of behavior at the
## individual level (party choice and abstention). Party choice
## predictions are only applied to individuals who do not report
## intended behavior. Absention predictions are applied based on the
## optimal cutoff or user-set cutoff. Estimates are weighed to
## electoral results of the previous election.

library(yaml)
library(tidyr)
library(ggplot2); theme_set(theme_bw())


## ---------------------------------------- 
## Read in data and configuration

list2env(read_yaml("./config/config.yaml"), envir=globalenv())
bop <- readRDS(file.path(DTA_FOLDER, "clean-bop.RDS"))

## Recall weights
recall_weights <- readRDS(file.path(DTA_FOLDER, "weight.RDS"))

## Predicted behavior
p_partychoice <- readRDS(file.path(DTA_FOLDER, "predicted-partychoice.RDS"))
p_voting <- readRDS(file.path(DTA_FOLDER, "predicted-voting.RDS"))
thr_voting <- readRDS(file.path(DTA_FOLDER, "thr-predicted-voting.RDS"))

## Join all results
bop <- merge(bop, recall_weights, by="id")
bop <- merge(bop, p_partychoice, by="id")
bop <- merge(bop, p_voting, by="id") ## Probability of voting

## ---------------------------------------- 
## Consolidate results

bop$abstention_twofactor <- as.factor(ifelse(bop$abstention %in%
                                               c("Probablement aniria a votar",
                                                 "Segur que aniria a votar"),
                                             "Will.vote",
                                             "Will.not.vote"))
bop$abstention_twofactor[is.na(bop$abstention)] <- NA

## Predicted behavior defaults to reported behavior
bop$p_intention <- bop$intention
## If they did not report a party choice, assign the predicted 
bop$p_intention[is.na(bop$intention)] <- bop$p_partychoice[is.na(bop$intention)]
## If they declare they will not vote, use that behavior
levels(bop$p_intention) <- c(levels(bop$p_intention), "No.votaria")
bop$p_intention[bop$abstention_twofactor == "Will.not.vote"] <- "No.votaria"
## Assign to voting all respondents with low predicted probability
## of voting (relative to cutoff)
bop$p_intention[(bop$p_voting < thr_voting) & is.na(bop$intention)] <- "No.votaria"

bop$p_intention <- droplevels(bop$p_intention)

## Save results 
saveRDS(data.frame("id"=bop$id,
                   "p_intention"=bop$p_intention,
                   "weight"=bop$weight),
        file.path(DTA_FOLDER, "individual-behavior.RDS"))

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
saveRDS(estimates, file.path(DTA_FOLDER, "estimated-vote-share.RDS"))

## ---------------------------------------- 
## Simulated effect of turnout rates

## An assumption in this chunk is that we are allowed to flip people
## who have reported a vote intention

turnout <- seq(.4, 1, by=0.01) ## True turnout will trail expected turnout
n_notvoting <- (1 - turnout) * 
  (nrow(bop) - sum(bop$abstention_twofactor == "Will.not.vote", na.rm=TRUE))

vote <- bop$intention
vote[is.na(bop$intention)] <- bop$p_partychoice[is.na(bop$intention)]
vote <- rep(list(as.character(vote)), length(turnout))

## Predicted as abstainers (among those who have reported they will vote)
pabstainers <- lapply(round(n_notvoting),
                      \(x) sort(bop$p_voting[bop$abstention_twofactor == "Will.vote"])[1:x])
last_prob_pabstainers <- lapply(pabstainers, max)

for (i in seq_along(last_prob_pabstainers)) {
  pabstainers[[i]] <- which(bop$p_voting < last_prob_pabstainers[[i]] &
                              bop$abstention_twofactor == "Will.vote")
}

## Declared as abstainers
dabstainers <- rep(list(which(bop$abstention_twofactor == "Will.not.vote")),
                   length(turnout))
abstainers <- mapply(function(x, y) unique(c(x, y)),
                     x=pabstainers,
                     y=dabstainers)

for (i in seq_along(turnout)) vote[[i]][abstainers[[i]]] <- "No.votaria"

sim <- as.data.frame(sapply(vote,
                            \(x) prop.table(xtabs(bop$weight ~ x,
                                                  subset=x != "No.votaria"))))
eturnout <- 1 - sapply(vote,
                       \(x) prop.table(xtabs(weight ~ x == "No.votaria",
                                             data=bop))["TRUE"]) ## Actual turnout

names(sim) <- paste0("p", turnout*100)
sim$party <- rownames(sim)

sim <- reshape(sim,
               varying=1:length(turnout),
               direction="long",
               v.names="share",
               timevar="p")

sim$ep <- rep(eturnout, each=9)

## Relation between turnout levels and probability of abstaining
pt_turnout <- cbind.data.frame(turnout, eturnout)
pt_turnout$last_prob_pabstainers <- unlist(last_prob_pabstainers)

p <- ggplot(pt_turnout, aes(x=last_prob_pabstainers, y=eturnout))
pq <- p + geom_line() + 
  labs(title="Threshold probability of voting and expected turnout",
       x="Probability of voting",
       y="Expected turnout rate") +
  geom_vline(xintercept=thr_voting, linetype=2) +
  lims(y=c(0, 1), x=c(0, 1))
ggsave(file.path(IMG_FOLDER, "pvoting-turnout.pdf"), pq)

## Because we are keeping everyone who declared to abstain with their
## reported choice, the maximum turnout is the declared turnout
p <- ggplot(sim, aes(x=ep, y=share, group=party, colour=party))
pq <- p + geom_line() +
  labs(title="Effect of simulated turnout on vote share",
       x="Turnout rate",
       y="Vote share") +
  lims(x=c(0, 1),
       y=c(0, .3)) +
  scale_color_discrete("Party")
 
ggsave(file.path(IMG_FOLDER, "simulation-voting.pdf"), pq)
 
