#!/usr/bin/env zsh

mkdir -p data/processed/temp

tar Oxvzf data/ghcnd_data/ghcnd_all.tar.gz | grep -E "(PRCP|TMAX)" | \
split -l 250000 --filter 'gzip > data/processed/temp/$FILE.gz'