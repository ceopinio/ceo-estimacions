#!/usr/bin/env Rscript

## Creates figures for the final report

library(yaml)
library(haven)
library(ggplot2)
library(forcats)
library(dplyr)
library(escons)
library(tidyr)
library(ggsankey)
library(MESS)

## ---------------------------------------- 
## Read in data and configuration

list2env(read_yaml("./config/config.yaml"), envir=globalenv())

bop <- read_sav(file.path(RAW_DTA_FOLDER, "Microdades anonimitzades 1031.sav"))
evotes <- readRDS(file.path(DTA_FOLDER, "estimated-vote-share.RDS"))
eseats <- readRDS(file.path(DTA_FOLDER, "seats.RDS"))

## Party colors

party_color <- unlist(lapply(COLORS, \(x) x[1]))
party_color_alpha  <- unlist(lapply(COLORS, \(x) x[2]))

## Prettify party names

prettify_party_names <- function(x) {
  if (!is.factor(x)) {
    stop("Party variable is expected to be a factor")
  }
  
  for (i in levels(x)) {
    if (i %in% names(PRETTY_PARTY_NAMES)) {
      levels(x)[which(levels(x) == i)] <- as.character(PRETTY_PARTY_NAMES[i])
    }
  }
  
  return(x)
}


## ---------------------------------------- 
## Estimate vote shares

## Prettify names
evotes$party <- prettify_party_names(evotes$party)

## Calculate CI
evotes <- subset(evotes, party != c("No.votaria"))

evotes$propvote <- evotes$weighted/sum(evotes$weighted) 

moe <- moe(evotes$propvote, nrow(bop), .95)
evotes$lb <- evotes$propvote - moe
evotes$ub <- evotes$propvote + moe

evotes <- evotes |>
  mutate(propvote=propvote * 100,
         ub=ub * 100,
         lb=lb * 100)

evotes <- evotes[!evotes$party %in% c("Altres"),
                 c("party", "weighted", "propvote", "lb", "ub")]

## Sort levels by results
sorted_levels <- evotes$party[order(evotes$propvote, decreasing=TRUE)]
evotes$party <- factor(evotes$party, levels=as.character(sorted_levels))

## Sort colors to match levels in data
evotes_party_color <- party_color[levels(evotes$party)]
evotes_party_color_alpha <- party_color_alpha[levels(evotes$party)]

## Report plot
p <- ggplot(evotes,
            aes(party, propvote, fill=party))
pq <- p + geom_col(width=0.7,
           show.legend=FALSE) +
  geom_hline(aes(yintercept=0)) +
  geom_crossbar(aes(x=party,
                    y=propvote,
                    ymin=lb,
                    ymax=ub,
                    fill=party,
                    color=party),
                width=0.7,
                alpha=0.5,
                linetype=3,
                fatten=0) +
  geom_text(size=3,
            aes(party,
                label=round(ub, digits=0),
                y=ub),
            vjust=-.5) +
  geom_text(size=3,
            aes(party,
                label=round(lb, digits=0),
                y=lb),
            vjust=1.5) +
  scale_fill_manual(values=evotes_party_color_alpha) +
  scale_color_manual(values=evotes_party_color) +
  scale_y_continuous(limits=c(0, 30),
                     labels=c("0", "10", "20", "30")) +
  theme_minimal() +
  theme(legend.position="none",
        panel.grid.minor.x=element_blank(),
        panel.grid.major.x=element_blank(),
        panel.grid.minor.y=element_blank(),
        plot.background=element_rect(fill="white",
                                     colour="white"),
        plot.margin=margin(0.5, 0.5, 0, 0.5, "cm"),
        axis.title.y=element_text(margin=margin(0, 0.5, 0, 0, "cm"),
                                  face="italic"),
        text=element_text(face="bold")) +
  labs(x="",
       y="Percentatge de vot (IC95%)")

ggsave(file.path(IMG_FOLDER, "figevots.png"), pq,
       units="in", width=8, height=8, dpi=300)


## ---------------------------------------- 
## Estimated seat distribution

## Prettify names
eseats$party <- as.factor(eseats$party)
eseats$party <- prettify_party_names(eseats$party)

## Sort levels by results
sorted_levels <- eseats$party[order(eseats$hi95,
                                    decreasing=TRUE)]
eseats$party <- factor(eseats$party,
                       levels=sorted_levels)

## Sort colors to match levels in data
eseats_party_color <- party_color[levels(eseats$party)]
eseats_party_color_alpha <- party_color_alpha[levels(eseats$party)]

## Report plot
p <- ggplot(eseats,
            aes(party, median, fill=party))

pq <- p +
  geom_col(width=0.7, show.legend=FALSE) +
  geom_hline(aes(yintercept = 0)) +
  geom_crossbar(aes(x=party,
                    y=median,
                    ymin=lo05,
                    ymax=hi95,
                    fill=party,
                    color=party),
                width=0.7,
                alpha=0.5,
                linetype=3,
                fatten=0) +
  geom_text(aes(party,
                label=hi95,
                y=hi95),
            vjust=-.5) +
  geom_text(aes(party,
                label=lo05,
                y=lo05),
            vjust=1.5) +
  scale_fill_manual(values=eseats_party_color) +
  scale_color_manual(values=eseats_party_color_alpha) +
  scale_y_continuous(limits=c(0, 42),
                     labels=c("0", "10", "20", "30", "40")) +
  theme_minimal() +
  theme(legend.position="none",
        panel.grid.minor.x=element_blank(),
        panel.grid.major.x=element_blank(),
        panel.grid.minor.y=element_blank(),
        plot.background=element_rect(fill="white",
                                     colour="white"),
        plot.margin=margin(0.5, 0.5, 0, 0.5, "cm"),
        axis.title.y=element_text(margin=margin(0, 0.5, 0, 0, "cm"),
                                    face="italic"),
        text=element_text(face="bold")) +
  labs(x="", 
       y="Escons (Percentils 5 i 95 de simulacions)")

ggsave(file.path(IMG_FOLDER, "figescons.png"), pq,
       units="in", width=8, height=8, dpi=300)

