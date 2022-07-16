#!/usr/bin/env Rscript

## Estimates seat distribution using district vote shares. The
## simulation uses the MOE of the estimate district vote share and
## returns the 5 and 95 percentile of the seats. 

library(escons)
library(yaml)
library(dplyr)

## ---------------------------------------- 
## Read in data and configuration

N <- 2000 ## Sample size to be used in simulation

list2env(read_yaml("./config/config.yaml"), envir=globalenv())
district_share <- readRDS(file.path(DTA_FOLDER, "vote-share-district.RDS"))

district_share <- as.data.frame(district_share)

## ---------------------------------------- 
## Seat simulation

## Reshape to data.frame with parties in rows and districts in columns
district_share <- reshape(district_share,
                          timevar="provincia",
                          idvar="p_intention",
                          direction="wide")

district_share <- district_share[district_share$p_intention != "Altres.partits", ]
names(district_share) <- gsub("Freq.", "", names(district_share))
party_names <- district_share$p_intention
district_share$p_intention <- NULL

## Simulate share distribution
simulated_seats <- simulate(district_share,
                            moe(district_share, N, 0.95),
                            names=party_names)

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
