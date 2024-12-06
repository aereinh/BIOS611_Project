FROM rocker/rstudio

RUN R -e "install.packages(c('dplyr','caret','nnet','adabag'))"

RUN apt update && apt install -y man-db && yes | unminimize && rm -rf /var/lib/apt/lists/*
