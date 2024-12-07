FROM rocker/rstudio:latest

RUN R -e "install.packages(c('dplyr', 'pheatmap', 'ggdendro','cowplot','ggplot2', 'seewave', 'knitr', 'rmarkdown'))"

RUN R -e "install.packages(c('tuneR','reshape2'))"
