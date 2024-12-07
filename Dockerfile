FROM rocker/rstudio

RUN R -e "install.packages(c('dplyr','ggplot2','cowplot', 'caret', 'keras'))"
