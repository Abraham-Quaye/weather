#!/usr/bin/env zsh

cd ~/weather && echo "Now in Weather directory" || "Could not find Weather Directory"

# # activate conda environment
# eval "$(conda shell.zsh hook)"
# conda activate weather &&
# echo "Weather environment activated successfully!!! " ||
# (echo "Environment activation Error!!!" ; exit)

# snakemake -c1 -R fetch_ghcnd_data
# snakemake -c1 -R run_project

git add .
echo "files staged to commit"
git commit -m "Added script to run pipeline on schedule"
git push
