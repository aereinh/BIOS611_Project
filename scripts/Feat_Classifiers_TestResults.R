library(dplyr)
library(cowplot)
library(ggplot2)
library(adabag)
library(nnet)
library(caret)
library(glmnet)

df30_full <- read.csv('data/features_30_sec.csv')
df30 <- df30_full %>%
  select(-c("filename","length")) %>%
  mutate(across(-label, scale)) %>%
  mutate(label = factor(label))

# Get Test data
trainInds30 <- readRDS('models/trainInds30.rds')
df_test30 <- df30[-trainInds30,]

# Evaluate test performance of classifiers
multinom_30 <- readRDS('models/multinom_30.rds')
elnet_30 <- readRDS('models/elnet_30.rds')
nn_30 <- readRDS('models/nnet_30.rds')
adaboost_30 <- readRDS('models/adaboost_30.rds')

ytest <- df_test30$label
ypred_multinom <- predict(multinom_30, df_test30)
ypred_elnet <- predict(elnet_30, df_test30)
ypred_nn <- predict(nn_30, df_test30)
ypred_adaboost <- predict(adaboost_30, df_test30)

# Compute metrics
compute_metrics <- function(y_true, y_pred, model) {
  genres <- levels(y_true)
  cm <- table(y_true, y_pred)
  acc <- diag(cm) / rowSums(cm)
  precision <- diag(cm) / colSums(cm)
  recall <- diag(cm) / rowSums(cm)
  f1 <- 2 * (precision * recall) / (precision + recall)
  data.frame(
    model = model,
    Genre = genres,
    Accuracy = acc,
    F1 = f1
  )
}

metrics_multinom <- compute_metrics(ytest, ypred_multinom, "Logistic Regression")
metrics_elnet <- compute_metrics(ytest, ypred_elnet, "Elastic Net")
metrics_nn <- compute_metrics(ytest, ypred_nn, "Single-Layer NN")
metrics_adaboost <- compute_metrics(ytest, ypred_adaboost, "Adaboost")
metrics_all <- rbind(metrics_multinom, metrics_elnet, metrics_nn, metrics_adaboost)
test_plot <- metrics_all %>% 
  #pivot_longer(cols = c("Accuracy","F1"), names_to = "Metric", values_to = "Value") %>%
  ggplot(aes(x = Genre, y = Accuracy, fill = factor(model)))+
  geom_bar(stat = "identity", position = "dodge", alpha = .9)+
  #facet_wrap(vars(Metric))+
  theme_bw(base_size=18)+
  labs(fill = "Model")+
  ggtitle('Test Set Accuracies for Derived Feature-Based Models')

ggsave(
  filename = "figures/test_feat.png",  # File name
  plot = test_plot,                   # The plot object to save
  width = 16,                             # Width of the plot in inches
  height = 10,                            # Height of the plot in inches
  dpi = 300                               # Resolution (dots per inch)
)

