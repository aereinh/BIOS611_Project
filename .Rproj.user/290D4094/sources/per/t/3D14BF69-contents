FROM rocker/rstudio

RUN R -e "install.packages('tidyverse')"

RUN apt update && apt install -y man-db && yes | unminimize && rm -rf /var/lib/apt/lists/*
