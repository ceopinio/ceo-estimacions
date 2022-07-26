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

bop <- read_sav(file.path(RAW_DTA_FOLDER, "BOP222.sav"))
evotes <- readRDS(file.path(DTA_FOLDER, "estimated-vote-share.RDS"))
eseats <- readRDS(file.path(DTA_FOLDER, "seats.RDS"))
p_recall <- readRDS(file.path(DTA_FOLDER, "predicted-recall.RDS"))
p_behavior <- readRDS(file.path(DTA_FOLDER, "individual-behavior.RDS"))
p_voting <- readRDS(file.path(DTA_FOLDER, "predicted-partychoice.RDS"))
p_transfer <- merge(p_recall, p_behavior, by="id")
p_transfer <- merge(p_transfer, p_voting, by="id")

## Party colors

party_color <- unlist(lapply(COLORS, \(x) x[1]))
party_color_alpha  <- unlist(lapply(COLORS, \(x) x[2]))

## Prettify party names

prettify_party_names <- function(x) {
  if (!is.factor(x)) {
    stop("Party variable is expected to be a factor")
  }
  
  for (i in levels(x)) {
    if (i %in% PRETTY_PARTY_NAMES) {
      levels(x)[which(levels(x) == i)] <- as.character(PRETTY_PARTY_NAMES[i])
    }
  }
  
  return(x)
}


## ---------------------------------------- 
## Estimate vote shares

## Prettify names
evotes$party <- prettify_party_names(evotes$party)

## Normalize results to candidacies and calculate CI
evotes <- evotes[!evotes$party %in% c("Altres", "No.votaria"),
                 c("party", "weighted")]

evotes$propvote <- evotes$weighted/sum(evotes$weighted) 

moe <- moe(evotes$propvote, nrow(bop), .95)
evotes$lb <- evotes$propvote - moe
evotes$ub <- evotes$propvote + moe

evotes <- evotes |>
  mutate(propvote=propvote * 100,
         ub=ub * 100,
         lb=lb * 100)

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
  scale_y_continuous(labels=c("0", "5", "10", "15")) +
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


## ---------------------------------------- 

## Heatmapf of transference

hmap_p <- p_transfer %>%
  group_by(p_intention, p_recall, .drop = FALSE) %>%
  summarize(n=length(p_recall)) %>%
  ungroup() %>%
  complete(p_recall,
           p_intention,
           fill=list(n=0, freq=0)) %>%
  group_by(p_recall) %>%
  mutate(proportion=(n / sum(n))*100) %>%
  mutate(proportion=round_percent(proportion, decimals = 0)) 

hmap_p <- hmap_p%>%
  mutate(p_intention=case_when(p_intention == "PSCPSOE" ~ "PSC",
                               p_intention == "En.Comu.Podem" ~ "ECP",
                               p_intention == "Junts.per.Catalunya" ~ "Junts",
                               p_intention == "No.votaria" ~ "BAI",
                               p_intention == "PP" ~ "PP",
                               p_intention == "ERC" ~ "ERC",
                               p_intention == "Cs" ~ "Cs",
                               p_intention == "CUP" ~ "CUP",
                               p_intention == "Vox" ~ "Vox",
                               p_intention == "Altres" ~ "Altres"),
         p_recall=case_when(p_recall == "PSCPSOE" ~ "PSC",
                            p_recall == "PP" ~ "PP",
                            p_recall == "ERC" ~ "ERC",
                            p_recall == "Cs" ~ "Cs",
                            p_recall == "CUP" ~ "CUP",
                            p_recall == "Vox" ~ "Vox",
                            p_recall == "En.Comu.Podem" ~ "ECP",
                            p_recall == "Junts.per.Catalunya" ~ "Junts",
                            p_recall == "Altres.partits" ~ "Altres",
                            p_recall == "No.va.votar" ~ "BAI"))


## Order of parties in plot
partits_level <- c("PSC",
                   "ERC",
                   "Junts",
                   "Vox",
                   "CUP",
                   "ECP",
                   "Cs",
                   "PP",
                   "Altres",
                   "BAI")

## Plot heatmap

p <- ggplot(hmap_p)

pq <- p +
  geom_tile(aes(fct_relevel(p_recall, partits_level),
                fct_relevel(p_intention, partits_level),
                fill=p_intention,
                alpha=proportion),
            color="white",
            size=1) +
  geom_text(aes(p_intention,
                p_recall,
                label=proportion),
            color="white",
            size=5,
            fontface="bold") +
  scale_y_discrete(limits=rev) +
  scale_x_discrete(position="top") +
  scale_fill_manual(values=as.vector(c("#AEAEAE", #Altres
                                       "#AEAEAE", #BAI
                                       party_color_alpha["Cs"],
                                       party_color_alpha["CUP"],
                                       party_color_alpha["ECP"],
                                       party_color_alpha["ERC"],
                                       party_color_alpha["Junts"],
                                       party_color_alpha["PP"],
                                       party_color_alpha["PSC"],
                                       party_color_alpha["Vox"]))) +
  scale_alpha_continuous(limits=c(0, 15),
                         range=c(0.3, 1)) +
  theme_minimal() +
  theme(legend.position="none",
        panel.grid.minor.x=element_blank(),
        panel.grid.major.x=element_blank(),
        panel.grid.minor.y=element_blank(),
        panel.grid.major.y=element_blank(),
        plot.background=element_rect(fill="white",
                                     colour="white"),
        plot.margin=margin(0, 0.5, 0.5, 0, "cm")) +
  labs(x="Intenció 2022 (Estimació)", y="Record 2021")
pq
ggsave(file.path(IMG_FOLDER, "heatmap.png"), pq,
       units="in", width=8, height=8, dpi=300)


## Transference matrix sankey

## Data cleaning

sankey_p <- p_transfer %>%
  select(c(p_recall, p_intention)) %>%
  mutate(p_intention=case_when(p_intention == "PSCPSOE" ~ "PSC",
                               p_intention == "En.Comu.Podem" ~ "ECP",
                               p_intention == "Junts.per.Catalunya" ~ "Junts",
                               p_intention == "No.votaria" ~ "BAI",
                               p_intention == "PP" ~ "PP",
                               p_intention == "ERC" ~ "ERC",
                               p_intention == "Cs" ~ "Cs",
                               p_intention == "CUP" ~ "CUP",
                               p_intention == "Vox" ~ "Vox",
                               p_intention == "Altres" ~ "Altres"),
         p_recall=case_when(p_recall == "PSCPSOE" ~ "PSC",
                            p_recall == "PP" ~ "PP",
                            p_recall == "ERC" ~ "ERC",
                            p_recall == "Cs" ~ "Cs",
                            p_recall == "CUP" ~ "CUP",
                            p_recall == "Vox" ~ "Vox",
                            p_recall == "En.Comu.Podem" ~ "ECP",
                            p_recall == "Junts.per.Catalunya" ~ "Junts",
                            p_recall == "Altres.partits" ~ "Altres",
                            p_recall == "No.va.votar" ~ "BAI"))

sankeydf <- sankey %>%
  ggsankey::make_long(vote, intention)

sankeydf$node <- factor(sankeydf$node,
                        levels=c("BAI", #Change levels by vote %
                                 "Altres",
                                 "Cs",
                                 "PP",
                                 "ECP",
                                 "CEC",
                                 "CUP",
                                 "Vox",
                                 "Junts",
                                 "ERC",
                                 "PSC"))
sankeydf$next_node <- factor(sankeydf$next_node,
                             levels=c("BAI",
                                      "Altres",
                                      "Cs",
                                      "PP",
                                      "ECP",
                                      "CUP",
                                      "Vox",
                                      "Junts",
                                      "ERC",
                                      "PSC"))

## Plot
p <- ggplot(sankeydf, aes(x=x,
                          next_x=next_x,
                          node=node,
                          next_node=next_node,
                          fill=factor(node),
                          label=node))

pq <- p + geom_sankey(flow.alpha=.4,
                      node.color="white",
                      show.legend=TRUE,
                      size=2,
                      smooth=6) +
  geom_sankey_label(size=3.5, 
                    color="gray20",
                    fill="white") +
  scale_fill_manual(values=as.vector(c("#AEAEAE", #Altres
                                       "#AEAEAE", #BAI
                                       party_color_alpha["ECP"],
                                       party_color_alpha["Cs"],
                                       party_color_alpha["CUP"],
                                       party_color_alpha["ECP"],
                                       party_color_alpha["ERC"],
                                       party_color_alpha["Junts"],
                                       party_color_alpha["PP"],
                                       party_color_alpha["PSC"],
                                       party_color_alpha["Vox"]))) +
  theme_void() +
  theme(legend.position="none",
        plot.background=element_rect(fill="white",
                                     colour="white"))

pq
ggsave(file.path(IMG_FOLDER, "sankey.png"), pq,
       units="in", width=8, height=8, dpi=300)
