#!/usr/bin/env zsh

mkdir -p data/processed/temp

tar Oxvzf data/ghcnd_data/ghcnd_all.tar.gz | grep "PRCP" | \
split -l 500000 --filter 'gzip > data/processed/temp/$FILE.gz'