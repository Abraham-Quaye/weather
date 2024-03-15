#!/usr/bin/env zsh

# README file https://www.ncei.noaa.gov/pub/data/ghcn/daily/readme.txt

files=(ghcnd_all.tar.gz ghcnd-inventory.txt ghcnd-stations.txt)

for f in $files; do
    echo "Downloading ${f} ..."
    wget -P data/ghcnd_data/ https://www.ncei.noaa.gov/pub/data/ghcn/daily/${f}
    echo "${f} download complete!!!"
done