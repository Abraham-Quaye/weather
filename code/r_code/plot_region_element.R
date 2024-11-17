#!/usr/bin/env Rscript

library(tidyverse)
library(lubridate)
library(maps)
library(glue)

# load-in processed prcp data and geographic metadata

prcp_data <- read_tsv("data/processed/tidy_prcp_data.tsv.gz") %>%
  rename(measure = element)

tmax_data <- read_tsv("data/processed/tidy_tmax_data.tsv.gz") %>%
  rename(measure = element)

geog_rawdata <- read_tsv("data/processed/geog_metadata.tsv.gz")

elemnt_geog <- function(elmnt){
  return(geog_rawdata %>%
           filter(element == elmnt) %>%
           select(-element))
}

geog_metadata <- purrr::map(c("PRCP", "TMAX"), elemnt_geog) %>%
  set_names(c("prcp", "tmax"))

mod_today <- today() - 1
this_yr <- year(mod_today)
year_to_plot <- this_yr

# join data and remove incomplete data
join_metadata <- function(df, elmnt){
  
  inner_join(df, geog_metadata[[elmnt]], by = "id") %>%
    filter((year != first_yr & year != last_yr) | year == this_yr) %>%
    group_by(lat, long, year) %>%
    reframe(mean_measure = mean(measure))
}

full_data <- purrr::map2(list(prcp_data, tmax_data), list("prcp", "tmax"),
                         join_metadata) %>%
  set_names(c("prcp", "tmax"))

# for each location (lat and long), find the z-score
make_plt_ready_data <- function(elmnt){
  full_data[[elmnt]] %>%
    group_by(lat, long) %>%
    mutate(zscore = (mean_measure - mean(mean_measure))/sd(mean_measure),
           years_recorded = n()) %>%
    ungroup() %>%
    # see how the weather (z-score) for any year of interest compares to >= last 30 years
    filter(years_recorded >= 30 & year == year_to_plot) %>%
    select(lat, long, zscore) %>%
    # adjust the z-scores for proper scaling of plot
    # (use histogram to see that most values are less than 2)
    mutate(zscore = case_when(zscore >= 2 ~ 2,
                              zscore <= -2 ~ -2,
                              TRUE ~ zscore))
}

ready_to_plt <- purrr::map(c("prcp", "tmax"), make_plt_ready_data) %>%
  set_names(c("prcp", "tmax"))

# ------- logic for date ranges
mod_end_yr <- year(mod_today)
mod_start_yr <- year(mod_today - 30)
mod_end_mnth <- month(mod_today)
mod_start_mnth <- month(mod_today - 30)

date_start <- case_when(
                        # same month, same year
                        ((mod_start_mnth == mod_end_mnth &
                            mod_start_yr == mod_end_yr) |
                        # different month, same year
                        (mod_start_mnth != mod_end_mnth &
                           mod_start_yr == mod_end_yr)) ~ format(mod_today - 30, "%B %e"),
                        # different month, different year
                        (mod_start_mnth != mod_end_mnth &
                           mod_start_yr != mod_end_yr) ~ format(mod_today - 30, "%B %e, %Y"),
                        TRUE ~ NA_character_)

date_end <- case_when(
                      #same month, same year
                      (mod_start_mnth == mod_end_mnth &
                          mod_start_yr == mod_end_yr) ~ format(mod_today, "%e, %Y"),
     # different month, same year
                      ((mod_start_mnth != mod_end_mnth &
                          mod_start_yr == mod_end_yr) |
                         # different month, different year
                        (mod_start_mnth != mod_end_mnth &
                           mod_start_yr != mod_end_yr)) ~ format(mod_today, "%B %e, %Y")
   )

date_range <- glue("{date_start} to {date_end}")

# ----- map world outline
world <- map_data("world") %>%
  filter(region != "Antarctica")

utah <- map_data("state") %>%
  filter(region == "utah")

weather_plots <- function(elmnt){
  # color scheme for low and high
  lh <- case_when(elmnt == "prcp" ~ c("#ffff50", "#0000ff"),
                  elmnt == "tmax" ~ c("#0000ff", "#ffff50"),
                  TRUE ~ c("#ff0000", "#000000"))
  read_elmnt <- case_when(elmnt == "prcp" ~ "Precipitation Levels",
                          elmnt == "tmax" ~ "Temperatures",)
  
  ready_to_plt[[elmnt]] %>%
    ggplot(aes(long, lat, fill = zscore)) +
    # world map outlines
    geom_polygon(data = world,
                 aes(long, lat, group = group),
                 fill = NA, color = "grey30 ", linewidth = 0.1) +
    # plot the z-scores with geom_tile
    geom_tile() +
    # plot utah outline
    geom_polygon(data = utah, 
               aes(long, lat),
               fill = NA, color = "#000000", linewidth = 0.1) +
    # aesthetics -----
  coord_fixed() +
    scale_fill_gradient2(low = lh[[1]], mid = "#ffffff", high =lh[[2]] ,
                         midpoint = 0,
                         breaks = c(-2, -1, 0, 1, 2),
                         labels = c("<-2", "-1", "0", "1", ">2")) +
    labs(title = glue("Relative Global {read_elmnt} from {date_range}"),
         subtitle = "Standardized Z-scores for at Least the Last 30 Years of Records",
         caption = "Data obtained from NOAA GHCN daily records") +
    theme(plot.background = element_rect(fill = "#000000", color = "#000000"),
          panel.background = element_rect(fill = "#000000", color = "#000000"),
          panel.grid = element_blank(),
          axis.text = element_blank(),
          plot.title = element_text(size = 30, colour = "#ffffff",
                                    face = "bold", hjust = 0.5),
          plot.subtitle = element_text(size = 16, colour = "#ffffff",
                                       hjust = 0.5),
          plot.caption = element_text(size = 12, colour = "#f4f4f4"),
          legend.background = element_blank(),
          legend.text = element_text(colour = "#ffffff"),
          legend.justification = c(0, 0),
          legend.direction = "horizontal",
          legend.title.position = "top",
          legend.position.inside = c(0.05, 0.1),
          legend.position = c(0.05, 0.1),
          legend.key.width = unit(1.5, "cm"),
          legend.key.height = unit(0.2, "cm")
    )
}

plts <- purrr::map(c("prcp", "tmax"), weather_plots) %>%
  set_names(c("prcp", "tmax"))

save_wether <- function(p, name){
  ggsave(plot = p, paste0("plots/", name, "_plot.png"),
         dpi = 350, width = 15, height = 7.5)
}

purrr::map2(plts, list("prcp", "tmax"), save_wether)