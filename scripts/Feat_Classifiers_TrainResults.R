library(cowplot)
library(ggplot2)
library(adabag)
library(nnet)
library(caret)
library(glmnet)

# Evaluate performance of classifiers
multinom_30 <- readRDS('models/multinom_30.rds')
elnet_30 <- readRDS('models/elnet_30.rds')
nn_30 <- readRDS('models/nnet_30.rds')
adaboost_30 <- readRDS('models/adaboost_30.rds')

# Training Performance
plot_multinom <- plot(multinom_30, main = "Logistic Regression", ylab = "Accuracy")
plot_elnet <- plot(elnet_30, main = "Elastic Net", ylab = "Accuracy")
plot_nn <- plot(nn_30, main = "Single-Layer NN", ylab = "Accuracy")
plot_adaboost <- plot(adaboost_30, main = "Adaboost", ylab = "Accuracy")

training_plot <- plot_grid(
  plot_multinom, 
  plot_elnet, 
  plot_nn, 
  plot_adaboost, 
  labels = "AUTO",  # Automatically label panels A, B, C, D
  ncol = 2
) + 
  theme_bw(base_size=18)+
  theme(axis.line = element_blank(),
        axis.ticks = element_blank(),
        axis.text = element_blank())+
  ggtitle('Training for Derived Feature-Based Models')


ggsave(
  filename = "figures/training_feat.png",  # File name
  plot = training_plot,                   # The plot object to save
  width = 12,                             # Width of the plot in inches
  height = 10,                            # Height of the plot in inches
  dpi = 300                               # Resolution (dots per inch)
)
