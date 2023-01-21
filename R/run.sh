#!/bin/bash

echo "Calling R script to download data and write plot"
Rscript -e "source('./R/01_download_plot.R');"

# echo "Commiting plot to Github"
# if [[ "$(git status --porcelain)" != "" ]]; then
#     git config --global user.name 'RichPauloo'
#     git config --global user.email 'richpauloo@gmail.com'
#     git add *.png
#     git commit -m "Auto update daily plot"
#     git push
# fi
