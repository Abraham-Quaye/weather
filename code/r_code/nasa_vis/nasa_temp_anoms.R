#!/usr/bin/env Rscript

library(tidyverse)
library(lubridate)

# The following is a plain-text file in tabular format of temperature anomalies,
# i.e. deviations from the corresponding 1951-1980 means.

# https://data.giss.nasa.gov/gistemp/
csv_url <- "https://data.giss.nasa.gov/gistemp/tabledata_v4/GLB.Ts+dSST.csv"
# download.file(csv_url, destfile = "data/nasa_weather.csv")

weather_data <- read_csv(csv_url, skip = 1,
                         na = c("", "NA", "***"),
                         col_types = cols(.default = col_double()),
                         col_select = c(year = Year, all_of(month.abb))) %>%
  pivot_longer(-year, names_to = "month", values_to = "temp_diff") %>%
  mutate(month = factor(month, levels = month.abb)) %>%
  drop_na(temp_diff)

prev_dec <- weather_data %>%
  filter(month == "Dec") %>%
  mutate(year = year + 1,
         month = "prev_dec")

next_jan <- weather_data %>%
  filter(month == "Jan") %>%
  mutate(year = year - 1,
         month = "next_jan")

ready_data <- weather_data %>%
  bind_rows(prev_dec, next_jan) %>%
  mutate(month = factor(month, levels = c("prev_dec", month.abb, "next_jan")),
         month_number = as.numeric(month),
         this_year = year == max(year)) 

this_year_weather <- ready_data %>%
  slice_max(year) %>%
  slice_max(month_number)

ready_data %>%
  ggplot(aes(month_number, temp_diff, color = year, group = year,
             linewidth = this_year)) +
  geom_hline(yintercept = 0, color = "#ffffff", linewidth = 0.5) +
  geom_line() +
  geom_text(data = this_year_weather, aes(label = year),
            hjust = 0, nudge_x = 0.1, size = 7, fontface = "bold") +
  scale_y_continuous(breaks = seq(-0.8, 1.4, 0.2),
                     labels = format(seq(-0.8, 1.4, 0.2), nsmall = 1),
                     sec.axis = dup_axis(labels = NULL, name = NULL)) +
  scale_x_continuous(breaks = 2:13,
                     labels = month.abb,
                     sec.axis = dup_axis(labels = NULL, name = NULL)) +
  scale_linewidth_manual(breaks = c(T, F),
                         values = c(2, 0.25),
                         guide = NULL) +
  coord_cartesian(xlim = c(2, 13)) +
  scale_color_viridis_c(name = NULL,
                        breaks = seq(1880, 2020, 20),
                        labels = seq(1880, 2020, 20)) +
  labs(x = NULL,
       y = "Temperature change since pre-industrial times [\u00B0C]",
       title = "Global temperature change since 1880 by month") +
  theme(plot.background = element_rect(fill = "grey30", colour = "grey30"),
        plot.title = element_text(color = "#ffffff", size =  18, face = "bold",
                                  hjust = 0.5),
        panel.background = element_rect(fill = "#000000", color = "#ffffff"),
        panel.grid = element_blank(),
        axis.ticks = element_line(color = "#ffffff"),
        axis.ticks.length = unit(-5, "pt"),
        axis.text = element_text(color = "#ffffff", size = 14, face = "bold"),
        axis.title = element_text(colour = "#ffffff", size = 15, face = "bold"),
        legend.background = element_blank(),
        legend.text = element_text(colour = "#ffffff", size = 14),
        legend.key.height = unit(2.6, "cm"),
        legend.frame = element_rect(color = "#ffffff")
        )

ggsave("plots/temp_anomalies.png", height = 6, width = 8, dpi = 400)
