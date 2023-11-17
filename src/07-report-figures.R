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
library(MESS)

## ---------------------------------------- 
## Read in data and configuration

list2env(read_yaml("./config/config.yaml"), envir=globalenv())

bop <- read_sav(file.path(RAW_DTA_FOLDER, "Microdades_anonimitzades_1071.sav"))
bop$id <- 1:nrow(bop)

evotes <- readRDS(file.path(DTA_FOLDER, "estimated-vote-share.RDS"))
eseats <- readRDS(file.path(DTA_FOLDER, "seats.RDS"))

past_results <- read_csv2(file.path(RAW_DTA_FOLDER, "past_results_plots.csv"))
past_seats <- past_results |> select(party = code, past_seats = seats_2021) |> mutate(party = paste0("p", party))
past_vote <- past_results |> select(party = code, past_vote = vote_2021) |> mutate(party = paste0("p", party))

p_recall <- readRDS(file.path(DTA_FOLDER, "predicted-recall.RDS"))
p_behavior <- readRDS(file.path(DTA_FOLDER, "individual-behavior.RDS"))
p_voting <- readRDS(file.path(DTA_FOLDER, "predicted-partychoice.RDS"))
p_transfer <- merge(p_recall, p_behavior, by="id")
p_transfer <- merge(p_transfer, p_voting, by="id")

parlament_recall <- bop |>
  select(id, REC_PARLAMENT_VOT_R) |>
  mutate(
    REC_PARLAMENT_VOT_R = case_when( REC_PARLAMENT_VOT_R < 93 ~ REC_PARLAMENT_VOT_R, ## Vot ultimes eleccions
                                     REC_PARLAMENT_VOT_R %in% c(93, 94) ~ 80, ## "Altres partits" (with "nul" and "en blanc")
                                     REC_PARLAMENT_VOT_R > 96 ~ NA_real_), ## Vote recall)
  ) |>
  mutate(
    REC_PARLAMENT_VOT_R = case_when(is.na(REC_PARLAMENT_VOT_R) ~ "p9000",
                                    TRUE ~ paste0("p", REC_PARLAMENT_VOT_R))
  ) |>
  rename(p_recall = REC_PARLAMENT_VOT_R)

p_transfer1 <- merge(parlament_recall, p_behavior, by = "id")
p_transfer1 <- merge(p_transfer1, p_voting, by="id")

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

df_pretty_party <- data.frame(party = names(PRETTY_PARTY_NAMES),
                              pretty_party = unlist(PRETTY_PARTY_NAMES) )


## Estimate vote shares -------- 

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

levels_party <- ifelse( levels(evotes$party) != "No.votaria", paste0("p", levels(evotes$party)), levels(evotes$party) )
evotes <- evotes[!evotes$party %in% c(80), #Altres
                 c("party", "weighted", "propvote", "lb", "ub")] |>
  mutate(
    party = paste0("p", party),
    party = factor(party, levels_party)
  )

## Sort colors to match levels in data
evotes_party_color <- party_color[levels(evotes$party)]
evotes_party_color_alpha <- party_color_alpha[levels(evotes$party)]

## Join Past Results
evotes <- evotes |>
  left_join(past_vote, by = "party") |>
  left_join(df_pretty_party, by = "party")

## Sort levels by results
sorted_levels <- evotes$party[order(evotes$propvote, decreasing=TRUE)]
evotes$party <- factor(evotes$party, levels=as.character(sorted_levels))

sorted_levels_pretty <- evotes$pretty_party[order(evotes$propvote, decreasing=TRUE)]
evotes$pretty_party <- factor(evotes$pretty_party, levels=as.character(sorted_levels_pretty))


## Report plot
p_evotes <- ggplot(evotes,
                   aes(propvote, pretty_party,  fill=party))

pq_evotes <- p_evotes + geom_col(width = 0.5,
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
               y = pretty_party,
               fill = party),
           alpha = 0.5,
           width = 0.3,
           position = position_nudge(y = -0.3)) +
  geom_vline(aes(xintercept = 0)) +
  geom_text(aes(past_vote,
                label = round(past_vote, digits = 1), 
                y = pretty_party),
            hjust = -.1,
            vjust = 2,
            fontface = "italic",
            size = 2) +
  geom_text(aes(lb, 
                label=round(lb, digits=0), 
                y = pretty_party),
            hjust = 1.3,
            vjust = 0.1,
            fontface = "bold") +
  geom_text(aes(ub, 
                label=round(ub, digits=0), 
                y = pretty_party),
            hjust = -0.3,
            vjust = 0.1,
            fontface = "bold") +
  scale_y_discrete(limits = rev) +
  scale_x_continuous(limits = c(0,max(evotes$ub)+4), 
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
                                  size = 12,
                                  color = "black"),
        plot.subtitle = element_text(margin = margin(0,0,0.25,0, "cm"),
                                     color="#ACACAC",
                                     size = 10,
                                     face = "italic"),
        plot.title.position = "plot",
        plot.caption.position = "plot") +
  labs(title = "Percentatge de Vot vàlid (± 95%CI)", 
       subtitle = "vs Resultats 2021",
       x= "",
       y = "")

pq_evotes

ggsave(file.path(IMG_FOLDER, "figevots_parlament.svg"), pq_evotes,
       units="cm", width=15, height=10)


## Estimated seat distribution -------- 

## Prettify names
eseats <- eseats |> 
  mutate(
    party = as.factor(paste0("p", party))
  ) |>
  left_join(df_pretty_party, by = "party"
  ) |>
  mutate(
    party = factor(party, levels_party)
  )

## Sort colors to match levels in data
eseats_party_color <- party_color[levels(eseats$party)]
eseats_party_color_alpha <- party_color_alpha[levels(eseats$party)]

## Join Past Results
eseats <- eseats %>% left_join(past_seats, by = "party") %>%
  mutate(lo05 = round(lo05, 0))

## Sort levels by results
sorted_levels <- eseats$party[order(eseats$hi95, decreasing=TRUE)]
eseats$party <- factor(eseats$party, levels=sorted_levels)

sorted_levels_pretty <- eseats$pretty_party[order(eseats$hi95, decreasing=TRUE)]
eseats$pretty_party <- factor(eseats$pretty_party, levels=sorted_levels_pretty)


## Report plot
p_eseats <- ggplot(eseats,
                   aes(median, pretty_party, fill=party))

pq_eseats <- p_eseats +
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
               y = pretty_party,
               fill = party),
           alpha = 0.5,
           width = 0.3,
           position = position_nudge(y = -0.3)) +
  geom_vline(aes(xintercept = 0)) +
  geom_text(aes(past_seats, 
                label = past_seats, 
                y = pretty_party),
            hjust = -.1,
            vjust = 2,
            fontface = "italic",
            size = 2) +
  geom_text(aes(lo05, 
                label = lo05, 
                y = pretty_party),
            hjust = 1.3,
            vjust = 0.1,
            fontface = "bold") +
  geom_text(aes(hi95, 
                label = hi95, 
                y = pretty_party),
            hjust = -0.3,
            vjust = 0.1,
            fontface = "bold") +
  scale_fill_manual(values=evotes_party_color_alpha) +
  scale_color_manual(values=evotes_party_color) +
  scale_y_discrete(limits = rev) +
  scale_x_continuous(limits = c(0,max(eseats$hi95)+4), expand = c(0, 0)) +
  theme_minimal() +
  theme(legend.position = "none",
        panel.grid.major.y = element_blank(),
        axis.title.x = element_text(margin = margin(0.5,0,0,0, "cm")),
        plot.margin = margin(0.5,0.5,0,0.5, "cm"),
        text = element_text(family = "Arial", color  = "black"),
        plot.title = element_text(margin = margin(0.25,0,0.25,0, "cm"),
                                  face = "bold", 
                                  size = 12,
                                  color = "black"),
        plot.subtitle = element_text(margin = margin(0,0,0.25,0, "cm"),
                                     color="#ACACAC",
                                     size = 10,
                                     face = "italic"),
        plot.title.position = "plot",
        plot.caption.position = "plot") +
  labs(title = "Escons (± 95% CI)", 
       subtitle = "vs Resultats 2021",
       x= "",
       y = "")

pq_eseats

ggsave(file.path(IMG_FOLDER, "figescons_parlament.svg"), pq_eseats,
       units="cm", width=15, height=10)



## Heatmap of transference -------- 
hmap_p <- p_transfer1 |>
  mutate(
    p_intention = ifelse(p_intention == "No.votaria", "p9000", paste0("p", p_intention))
  ) |>
  group_by(p_intention, p_recall, .drop = FALSE) |>
  summarize(n=length(p_recall)) |>
  ungroup() |>
  ungroup() |>
  complete(p_recall,
           p_intention,
           fill=list(n=0, freq=0)) |>
  group_by(p_recall) |>
  mutate(proportion=(n / sum(n))*100) |>
  mutate(proportion=round_percent(proportion, decimals = 0)) |>
  ungroup() |>
  left_join(df_pretty_party |> rename(p_recall_pretty_party = pretty_party), by = c("p_recall" = "party")) |>
  left_join(df_pretty_party |> rename(p_intention_pretty_party = pretty_party), by = c("p_intention" = "party"))


## Sort levels by past results
partits_level <- c( df_pretty_party[past_vote$party[order(past_vote$past_vote, decreasing = T)], ]$pretty_party,
                    "Altres", "BAI")

## Plot heatmap
p_hmap <- ggplot(hmap_p)

pq_hmap <- p_hmap +
  geom_tile(aes(x = fct_relevel(p_intention_pretty_party, partits_level),
                y = fct_relevel(p_recall_pretty_party, partits_level),
                fill = p_recall,
                alpha=proportion),
            color="white",
            size=1) +
  geom_text(aes(p_intention_pretty_party,
                p_recall_pretty_party,
                label=proportion),
            color="white",
            size=6,
            fontface="bold") +
  scale_y_discrete(limits=rev) +
  scale_x_discrete(position="top") +
  scale_fill_manual(values=party_color_alpha) +
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
       y="Record de vot 2021")
pq_hmap
ggsave(file.path(IMG_FOLDER, "heatmap_parlament.svg"), pq_hmap,
       units="cm", width=17, height=10)

