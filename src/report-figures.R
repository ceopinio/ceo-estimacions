#!/usr/bin/env Rscript

## Creates figures for the final report

library(yaml)
library(ggplot2)
library(forcats)
library(dplyr)
library(readr)
library(haven)
library(escons)
library(tidyr)

## ---------------------------------------- 
## Read in data and configuration

list2env(read_yaml("./config/config.yaml"), envir=globalenv())

bop <- read_sav(file.path(RAW_DTA_FOLDER, "Microdades revisades_1061.sav"))

evotes <- readRDS(file.path(DTA_FOLDER, "estimated-vote-share.RDS"))
eseats <- readRDS(file.path(DTA_FOLDER, "seats.RDS"))

past_results <- read_csv2(file.path(RAW_DTA_FOLDER, "past_results_plots.csv"))
past_seats <- past_results %>% select(party, past_seats = seats_2019)
past_vote <- past_results %>% select(party, past_vote = votes_2019)

p_recall <- readRDS(file.path(DTA_FOLDER, "predicted-recall.RDS"))
p_behavior <- readRDS(file.path(DTA_FOLDER, "individual-behavior.RDS"))
p_voting <- readRDS(file.path(DTA_FOLDER, "predicted-partychoice.RDS"))
p_transfer <- merge(p_recall, p_behavior, by="id")
p_transfer <- merge(p_transfer, p_voting, by="id")

## Font (Only for Windows users)

windowsFonts(Arial=windowsFont("Arial"))

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

## Sort colors to match levels in data
evotes_party_color <- party_color[levels(evotes$party)]
evotes_party_color_alpha <- party_color_alpha[levels(evotes$party)]

## Join Past Results

evotes <- evotes %>% left_join(past_vote, by = "party")

## Sort levels by results
sorted_levels <- evotes$party[order(evotes$propvote, decreasing=TRUE)]
evotes$party <- factor(evotes$party, levels=as.character(sorted_levels))

## Report plot

p <- ggplot(evotes,
            aes(propvote, party,  fill=party))

pq <- p + geom_col(width = 0.5,
                   position = position_nudge(y = 0.12)) +
  geom_crossbar(aes(xmin = lb, 
                    xmax = ub,
                    fill = party,
                    color = party),
                width = 0.5,
                alpha = 0.5, 
                linetype = 3, 
                fatten = 0,
                position = position_nudge(y = 0.125)) +
  geom_col(aes(x = past_vote,
               y = party,
               fill = party),
           alpha = 0.5,
           width = 0.3,
           position = position_nudge(y = -0.3)) +
  geom_vline(aes(xintercept = 0)) +
  geom_text(aes(past_vote,
                label = round(past_vote, digits = 1), 
                y = party),
            hjust = -.1,
            vjust = 1.6,
            fontface = "italic",
            size = 3) +
  geom_text(aes(lb, 
                label=round(lb, digits=0), 
                y = party),
            hjust = 1.3,
            vjust = 0.1,
            fontface = "bold") +
  geom_text(aes(ub, 
                label=round(ub, digits=0), 
                y = party),
            hjust = -0.3,
            vjust = 0.1,
            fontface = "bold") +
  scale_y_discrete(limits = rev) +
  scale_x_continuous(limits = c(0,40), 
                     expand = c(0, 0)) +
  scale_fill_manual(values=evotes_party_color_alpha) +
  scale_color_manual(values=evotes_party_color) +
  theme_minimal() +
  theme(legend.position = "none",
        panel.grid.major.y = element_blank(),
        axis.title.x = element_text(margin = margin(0.5,0,0,0, "cm")),
        plot.margin = margin(0.5,0.5,0,0.5, "cm"),
        text = element_text(family = "Arial", color  = "black"),
        plot.title = element_text(margin = margin(0.25,0,0.25,0, "cm"),
                                  face = "bold", 
                                  size = 10,
                                  color = "black"),
        plot.subtitle = element_text(margin = margin(0,0,0.25,0, "cm"),
                                     color="#ACACAC",
                                     size = 10,
                                     face = "italic"),
        plot.title.position = "plot",
        plot.caption.position = "plot") +
  labs(title = "Percentatge de Vot vàlid (± 95%CI)", 
       subtitle = "vs Resultats 2019",
       x= "",
       y = "")
pq

ggsave(file.path(IMG_FOLDER, "figvots_congres.png"), pq,
       units="cm", width=15, height=10, dpi=300)

## ---------------------------------------- 
## Estimated seat distribution

## Prettify names
eseats$party <- as.factor(eseats$party)
eseats$party <- prettify_party_names(eseats$party)

## Sort colors to match levels in data
eseats_party_color <- party_color[levels(eseats$party)]
eseats_party_color_alpha <- party_color_alpha[levels(eseats$party)]

## Join Past Results

eseats <- eseats %>% left_join(past_seats, by = "party")

## Sort levels by results
sorted_levels <- eseats$party[order(eseats$hi95,
                                    decreasing=TRUE)]
eseats$party <- factor(eseats$party,
                       levels=sorted_levels)

## Report plot

p <- ggplot(eseats,
            aes(median, party, fill=party))
## Modificacio de l'ordre del gráfic per ordre d'escons
#new_order <- c("Ciudadanos", "CUP", "Vox", "PP", "Junts per Catalunya", "En Comú Podem",  "ERC", "PSC")

pq <- p +
  geom_col(aes(fill = party),
           width = 0.5,
           position = position_nudge(y = 0.12)) +
  geom_crossbar(aes(xmin = lo05, 
                    xmax = hi95,
                    fill = party,
                    color = party),
                width = 0.5,
                alpha = 0.5, 
                linetype = 3, 
                fatten = 0,
                position = position_nudge(y = 0.125)) +
  geom_col(aes(x = past_seats,
               y = party,
               fill = party),
           alpha = 0.5,
           width = 0.3,
           position = position_nudge(y = -0.3)) +
  geom_vline(aes(xintercept = 0)) +
  geom_text(aes(past_seats, 
                label = past_seats, 
                y = party),
            hjust = -.1,
            vjust = 1.6,
            fontface = "italic",
            size = 3) +
  geom_text(aes(lo05, 
                label = lo05, 
                y = party),
            hjust = 1.3,
            vjust = 0.1,
            fontface = "bold") +
  geom_text(aes(hi95, 
                label = hi95, 
                y = party),
            hjust = -0.3,
            vjust = 0.1,
            fontface = "bold") +
  scale_fill_manual(values=evotes_party_color_alpha) +
  scale_color_manual(values=evotes_party_color) +
  scale_y_discrete(limits = rev) +
  #scale_y_discrete(limits = new_order) +
  scale_x_continuous(limits = c(0, 20),
                     expand = c(0, 0)) +
  theme_minimal() +
  theme(legend.position = "none",
        panel.grid.major.y = element_blank(),
        axis.title.x = element_text(margin = margin(0.5,0,0,0, "cm")),
        plot.margin = margin(0.5,0.5,0,0.5, "cm"),
        text = element_text(family = "Arial", color  = "black"),
        plot.title = element_text(margin = margin(0.25,0,0.25,0, "cm"),
                                  face = "bold", 
                                  size = 10,
                                  color = "black"),
        plot.subtitle = element_text(margin = margin(0,0,0.25,0, "cm"),
                                     color="#ACACAC",
                                     size = 10,
                                     face = "italic"),
        plot.title.position = "plot",
        plot.caption.position = "plot") +
  labs(title = "Escons (± 95% CI)", 
       subtitle = "vs Resultats 2019",
       x= "",
       y = "")

pq

ggsave(file.path(IMG_FOLDER, "figescons_congres.png"), pq,
       units="cm", width=15, height=10, dpi=300)


## Heatmapf of transference

hmap_p <- p_transfer %>%
  mutate(p_recall = as.character(p_recall)) %>% 
  mutate(p_recall = if_else(p_recall %in% c("PDeCAT", "CiutadansCiudadanos"), "Altres", p_recall)) %>% 
  group_by(p_intention, p_recall, .drop = FALSE) %>%
  summarize(n=length(p_recall)) %>%
  ungroup() %>%
  complete(p_recall,
           p_intention,
           fill=list(n=0, freq=0)) %>%
  group_by(p_recall) %>%
  mutate(proportion=(n / sum(n))*100) %>%
  mutate(proportion=round_percent(proportion, decimals = 0)) 


hmap_p <- hmap_p %>%
  mutate(p_intention=case_when(p_intention == "PSCPSOE" ~ "PSC",
                               p_intention == "En.Comu.Podem" ~ "Sumar",
                               p_intention == "Junts.per.Catalunya" ~ "Junts",
                               p_intention == "PP" ~ "PP",
                               p_intention == "ERC" ~ "ERC",
                               p_intention == "CUP" ~ "CUP",
                               p_intention == "Vox" ~ "Vox",
                               p_intention == "Altres" ~ "Altres",
                               p_intention == "No.votaria" ~ "BAI",
                               TRUE ~ p_intention),
         p_recall=case_when(p_recall == "PSCPSOE" ~ "PSC",
                            p_recall == "PP" ~ "PP",
                            p_recall == "ERC" ~ "ERC",
                            p_recall == "CUP" ~ "CUP",
                            p_recall == "Vox" ~ "Vox",
                            p_recall == "En.Comu.Podem" ~ "Sumar",
                            p_recall == "Junts.per.Catalunya" ~ "Junts",
                            p_recall == "Altres" ~ "Altres",
                            p_recall == "No.va.votar" ~ "BAI", 
                            TRUE ~ p_recall))


## Order of parties in plot
partits_level <- c("ERC",
                   "PSC", 
                   "Junts",
                   "Sumar",
                   "PP",
                   "CUP",
                   "Vox",
                   "Cs",
                   "Altres",
                   "BAI")

partits_level2 <- c("ERC",
                    "PSC", 
                    "Junts",
                    "Sumar",
                    "PP",
                    "CUP",
                    "Vox",
                    "Altres",
                    "BAI")


## Plot heatmap

p <- ggplot(hmap_p)

pq <- p +
  geom_tile(aes(fct_relevel(p_intention, partits_level),
                fct_relevel(p_recall, partits_level),
                fill=p_recall,
                alpha=proportion),
            color="white",
            size=1) +
  geom_text(aes(p_intention,
                p_recall,
                label=proportion),
            color="white",
            size=4,
            fontface="bold") +
  scale_y_discrete(limits=rev) +
  scale_x_discrete(position="top") +
  scale_fill_manual(values=as.vector(c(Altres = "#AEAEAE", #Altres
                                       BAI = "#AEAEAE", #BAI,
                                       party_color_alpha["CUP"],
                                       party_color_alpha["ERC"],
                                       party_color_alpha["Junts"],
                                       party_color_alpha["PP"],
                                       party_color_alpha["PSC"],
                                       party_color_alpha["Sumar"],
                                       party_color_alpha["Vox"]))) +
  scale_alpha_continuous(limits=c(0, 10),
                         range=c(0.3, 1)) +
  theme_minimal() +
  theme(legend.position="none",
        panel.grid.minor.x=element_blank(),
        panel.grid.major.x=element_blank(),
        panel.grid.minor.y=element_blank(),
        panel.grid.major.y=element_blank(),
        plot.background=element_rect(fill="white",
                                     colour="white"),
        plot.margin=margin(0.5, 0.5, 0.5, 0.5, "cm"),
        axis.title.x.top = element_text(face = "bold",
                                        margin=margin(0, 0, 0.5, 0, "cm")),
        axis.title.y = element_text(face = "bold",
                                    margin=margin(0, 0.5, 0, 0, "cm"))) +
  labs(x="Estimació de vot 2023",
       y="Record de vot 2019")
pq
ggsave(file.path(IMG_FOLDER, "heatmap_congres.png"), pq,
       units="cm", width=15, height=10,  dpi=300)

