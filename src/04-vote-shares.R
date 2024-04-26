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
df <- readRDS(file.path(DTA_FOLDER, "clean-df.RDS"))

## Recall weights
recall_weights <- readRDS(file.path(DTA_FOLDER, "weight.RDS"))

## Predicted behavior
p_partychoice <- readRDS(file.path(DTA_FOLDER, "predicted-partychoice.RDS")) # Atenció
p_voting <- readRDS(file.path(DTA_FOLDER, "predicted-voting.RDS"))
thr_voting <- readRDS(file.path(DTA_FOLDER, "thr-predicted-voting.RDS"))

## Join all results
df <- merge(df, recall_weights, by="id")
df <- merge(df, p_partychoice, by="id")
df <- merge(df, p_voting, by="id") ## Probability of voting

## ---------------------------------------- 
## Consolidate results

df$abstention_twofactor <- as.factor(ifelse(df$abstention %in% c(3, 4), "Will.vote", "Will.not.vote"))
df$abstention_twofactor[is.na(df$abstention)] <- NA

## Predicted behavior defaults to reported behavior
df$p_intention <- df$intention
## If they did not report a party choice, assign the predicted 
df$p_intention[is.na(df$intention)] <- as.factor( sub("^p", "", df$p_partychoice[is.na(df$intention)]) )
## If they declare they will not vote, use that behavior
levels(df$p_intention) <- c(levels(df$p_intention), "No.votaria")
df$p_intention[df$abstention_twofactor == "Will.not.vote"] <- "No.votaria"
## Assign to nonvoters all respondents with low predicted probability of voting (relative to cutoff)
## We allow flipping in this case of telephone survey, to not overrate participation
df$p_intention[(df$p_voting < thr_voting)] <- "No.votaria"

df$p_intention <- droplevels(df$p_intention)

## Save results 
saveRDS(data.frame("id"=df$id,
                   "p_intention"=df$p_intention,
                   "weight"=df$weight),
        file.path(DTA_FOLDER, "individual-behavior.RDS"))

## ---------------------------------------- 
## Estimated vote shares

## Unweighted estimates
estimates <- prop.table(xtabs(~ p_intention, data=df))*100
estimates <- as.data.frame(estimates)
names(estimates)[names(estimates) == "Freq"] <- "unweighted"

## Weighted estimates
westimates <- prop.table(xtabs(weight ~ p_intention, data=df))*100
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
  (nrow(df) - sum(df$abstention_twofactor == "Will.not.vote", na.rm=TRUE))

vote <- df$intention
vote[is.na(df$intention)] <- as.factor( sub("^p", "", df$p_partychoice[is.na(df$intention)]) )
vote <- rep(list(as.character(vote)), length(turnout))

## Predicted as abstainers (among those who have reported they will vote)
pabstainers <- lapply(round(n_notvoting),
                      \(x) sort(df$p_voting[df$abstention_twofactor == "Will.vote"])[1:x])
last_prob_pabstainers <- lapply(pabstainers, max)

for (i in seq_along(last_prob_pabstainers)) {
  pabstainers[[i]] <- which(df$p_voting < last_prob_pabstainers[[i]] &
                              df$abstention_twofactor == "Will.vote")
}

## Declared as abstainers
dabstainers <- rep(list(which(df$abstention_twofactor == "Will.not.vote")),
                   length(turnout))
abstainers <- mapply(function(x, y) unique(c(x, y)),
                     x=pabstainers,
                     y=dabstainers)

for (i in seq_along(turnout)) vote[[i]][abstainers[[i]]] <- "No.votaria"

sim <- sapply(vote, \(x) prop.table(xtabs(df$weight ~ x,
                                                  subset=x != "No.votaria")))

# # Iterate through each element in the sim list
for (i in seq_along(sim)) {
   # Check if there is no element with name "6"
   if (!"6" %in% names(sim[[i]])) {
     # Create an element with name "6" and value 0
     sim[[i]]["6"] <- 0
   }
 }
 
 for (i in seq_along(sim)) {
   # Order the element based on its names
   sim[[i]] <- sim[[i]][order(names(sim[[i]]))]
 }
 
 sim <- do.call(cbind, sim)

eturnout <- 1 - sapply(vote,
                       \(x) prop.table(xtabs(weight ~ x == "No.votaria",
                                             data=df))["TRUE"]) ## Actual turnout

names(sim) <- paste0("p", turnout*100)
sim <- as.data.frame(sim)
sim$party <- rownames(sim)

sim <- reshape(sim,
               varying=1:length(turnout),
               direction="long",
               v.names="share",
               timevar="p")

sim$ep <- rep(eturnout, each=10)

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
## Add threshold line
eturnout_line <- pt_turnout %>%
  filter(abs(last_prob_pabstainers - thr_voting) == 
             min(abs(last_prob_pabstainers - thr_voting)))

p <- ggplot(sim, aes(x=ep, y=share, group=party, colour=party))
pq <- p + geom_line() +
  geom_vline(xintercept = eturnout_line$eturnout, linetype=2) +
  labs(title="Effect of simulated turnout on vote share",
       x="Turnout rate",
       y="Vote share") +
  lims(x=c(0, 1),
       y=c(0, .4)) +
  scale_color_discrete("Party")
 
ggsave(file.path(IMG_FOLDER, "simulation-voting.pdf"), pq)
 
