#!/usr/bin/env Rscript

## Estimates seat distribution using district vote shares. The
## simulation uses the MOE of the estimate district vote share and
## returns the 5 and 95 percentile of the seats. 

library(escons)
library(yaml)
library(dplyr)

## ---------------------------------------- 
## Read in data and configuration

N <- 1000 ## Sample size to be used in simulation

list2env(read_yaml("./config/config.yaml"), envir=globalenv())
district_share <- readRDS(file.path(DTA_FOLDER, "vote-share-district.RDS"))

district_share <- as.data.frame(t(district_share))

## ---------------------------------------- 
## Seat simulation

district_share <- district_share[rownames(district_share) != "Altres", ]

## Simulate share distribution
simulated_seats <- simulate(district_share,
                            moe(district_share, N, 0.95),
                            names=row.names(district_share))

simulated_seats <- as.data.frame(simulated_seats)
saveRDS(simulated_seats, file.path(DTA_FOLDER, "seats-simulation.RDS"))

## Keep 5, 50, and 95 percentile of the simulated distribution
simulated_seats <- simulated_seats |>
  group_by(party) |>
  summarize(lo05=quantile(total, 0.05),
            median=quantile(total, 0.5),
            hi95=quantile(total, .95))

## Save data
saveRDS(simulated_seats, file.path(DTA_FOLDER, "seats.RDS"))

## ---------------------------------------- 
## Plot the results

## Prettify names
simulated_seats$party <- recode_factor(simulated_seats$party,
                                       "PSCPSOE"="PSC",
                                       "En.Comu.Podem"="ECP",
                                       "Junts.per.Catalunya"="Junts")

## Sort levels by results
sorted_levels <- simulated_seats$party[order(simulated_seats$hi95,
                                             decreasing=TRUE)]
simulated_seats$party <- factor(simulated_seats$party,
                                levels=sorted_levels)

## Define party colors
party_color <- unlist(lapply(COLORS, \(x) x[1]))
party_color_alpha  <- unlist(lapply(COLORS, \(x) x[2]))

party_color <- party_color[levels(simulated_seats$party)]
party_color_alpha <- party_color_alpha[levels(simulated_seats$party)]

## Report plot
p <- ggplot(simulated_seats,
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
  scale_fill_manual(values=party_color) +
  scale_color_manual(values=party_color_alpha) + 
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
