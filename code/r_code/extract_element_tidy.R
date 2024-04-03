#!/usr/bin/env Rscript

library(tidyverse)
library(lubridate)
library(furrr)

# https://www.ncei.noaa.gov/pub/data/ghcn/daily/readme.txt
# ------------------------------
# Variable   Columns   Type
# ------------------------------
# ID            1-11   Character
# YEAR         12-15   Integer
# MONTH        16-17   Integer
# ELEMENT      18-21   Character
# VALUE1       22-26   Integer
# MFLAG1       27-27   Character
# QFLAG1       28-28   Character
# SFLAG1       29-29   Character
# VALUE2       30-34   Integer
# MFLAG2       35-35   Character
# QFLAG2       36-36   Character
# SFLAG2       37-37   Character
#   .           .          .
#   .           .          .
#   .           .          .
# VALUE31    262-266   Integer
# MFLAG31    267-267   Character
# QFLAG31    268-268   Character
# SFLAG31    269-269   Character
# ------------------------------

jul_tday <- yday(today() - 1)
window <- 30
# function to add col names to data
quad_labs <- function(x){
  quad <- c(paste0("value", x), paste0("mflag", x),
            paste0("qflag", x), paste0("sflag", x))
  return(quad)
}

data_widths = c(11, 4, 2, 4, rep(c(5, 1, 1, 1), 31))
data_colNames = c("id", "year", "month", "element",
                  unlist(map(1:31, quad_labs)))

process_daily_data <- function(frag_file, elmnt){
  print(paste("Now processing", frag_file))
  
  p_data <- read_fwf(frag_file,
           fwf_widths(widths = data_widths,
           col_names = data_colNames),
           na = c("NA", "-9999"),
           col_types = cols(.default = col_character()),
           col_select = c(id, year, month, element,
           starts_with("value"))) %>%
  pivot_longer(starts_with("value"),
               names_to = "day",
               values_to = "reading") %>%
  mutate(day = parse_number(day),
         date = ymd(paste0(year, "-", month, "-", day), quiet = T),
         reading  = ifelse(element == "PRCP",
                           as.numeric(reading)/100, # prcp in cm (from tenths of mm)
                           as.numeric(reading)/10 # tmax in C (from tenths of C)
                           )) %>%
  drop_na(date) %>%
  replace_na(list(reading = 0)) %>% 
  select(id, date, element, reading) %>%
  mutate(julian_day = yday(date),
         days_apart = jul_tday - julian_day,
         is_within_range = case_when(days_apart < window & days_apart > 0 ~ T,
                                     days_apart > window ~ F,
                                     julian_day < window & days_apart + 365 < window ~ T,
                                     days_apart < 0 ~ F),
         year = year(date),
         year = ifelse(days_apart < 0 & is_within_range, year + 1, year)
         ) %>%
  filter(is_within_range) %>%
  group_by(id, year, element) %>%
  summarise(m_reading = mean(reading), .groups = "drop") %>%
  filter(element == elmnt) %>%
  select(-element)
  
  return(p_data)
}

frag_files <- list.files("data/processed/temp",
                         pattern = "^x[a-z][a-z]\\.gz",
                         full.names = T)

tidy_element_data <- function(element){
  plan(multicore, workers = 9)
  future_map_dfr(frag_files,
                 ~process_daily_data(frag_file = .x, elmnt = element),
                 .progress = T) %>%
    group_by(id, year) %>%
    summarise(element = mean(m_reading), .groups = "drop") %>%
    write_tsv(., paste0("data/processed/tidy_", tolower(element), "_data.tsv.gz"),
              col_names = T)
}

map(c("PRCP", "TMAX"), tidy_element_data)

print("Script Complete!!!")