FROM rocker/verse:latest

RUN apt-get update && apt-get install -y libgl1-mesa-dev libx11-dev libxt-dev libglu1-mesa-dev make && apt-get clean

RUN R -e "install.packages(c('dplyr', 'pheatmap', 'ggdendro','cowplot','ggplot2', 'knitr', 'rmarkdown', 'DescTools'))"

WORKDIR /project

COPY . /project

RUN R -e "install.packages(c('caret','nnet','adabag'))"

RUN R -e "install.packages('glmnet')"

CMD ["/bin/bash"]
