FROM rocker/rstudio:latest-daily

#RUN install.r shiny forecast jsonlite ggplot2 htmltools

# make a dir for plots
RUN mkdir plots

# install packages
RUN mkdir packages
COPY install_packages.R packages/
COPY install_libs.sh packages/

RUN bash packages/install_libs.sh
RUN Rscript packages/install_packages.R
