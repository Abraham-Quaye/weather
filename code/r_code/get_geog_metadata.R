#!/usr/bin/env Rscript

library(tidyverse)

# https://www.ncei.noaa.gov/pub/data/ghcn/daily/readme.txt
# FORMAT OF "ghcnd-inventory.txt"
# 
# ------------------------------
#   Variable   Columns   Type
# ------------------------------
#   ID            1-11   Character
# LATITUDE     13-20   Real
# LONGITUDE    22-30   Real
# ELEMENT      32-35   Character
# FIRSTYEAR    37-40   Integer
# LASTYEAR     42-45   Integer
# ------------------------------

read_fwf("data/ghcnd_data/ghcnd-inventory.txt",
         fwf_cols(id = c(1, 11),
         lat = c(13, 20),
         long = c(22, 30),
         element = c(32, 35),
         first_yr = c(37, 40),
         last_yr = c(42, 45))) %>%
  filter(element == "PRCP") %>%
  select(-element) %>%
  mutate(lat = round(lat),
         long = round(long)) %>%
  group_by(lat, long) %>%
  write_tsv(., "data/processed/prcp_geog_metadata.tsv")