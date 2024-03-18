#!/usr/bin/env zsh

cd ~/weather && echo "Now in Weather directory" || "Could not find Weather Directory"

# activate conda environment
eval "$(conda shell.zsh hook)"
conda activate weather &&
echo "Weather environment activated successfully!!! " ||
(echo "Environment activation Error!!!" ; exit)

snakemake -c1 -R fetch_ghcnd_data
snakemake -c1 -R run_project

run_date=$(date | date | cut -d " " -f 2,3,6)

git add plots/prcp_plot.png

git commit -m "Updated Plot for $run_date"

git push
