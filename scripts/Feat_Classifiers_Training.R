library(dplyr)
library(nnet)
library(caret)
library(adabag)

set.seed(123)
kfolds <- 10 # cross-validation for tuning

df30_full <- read.csv('data/features_30_sec.csv')
df30 <- df30_full %>%
  select(-c("filename","length")) %>%
  mutate(across(-label, scale)) %>%
  mutate(label = factor(label))

# Train-Test split
trainInds30 <- createDataPartition(df30_full$label,times = 1, p = .8, list = F)
saveRDS(trainInds30, 'models/trainInds30.rds')

df_train30 <- df30[trainInds30,]
df_test30 <- df30[-trainInds30,]

# Train simple classifiers, using k-fold cross-validation for tuning
train_control <- trainControl(
  method = "cv",
  number = kfolds,
  savePredictions = "final",
  classProbs = T,
  verboseIter = T
)

multinom_grid <- expand.grid(decay = c(0.01, 0.1, 0.5))
multinom_30 <- train(label ~ .,data = df_train30,method = "multinom",trControl = train_control, tuneGrid = multinom_grid)
saveRDS(multinom_30, file = 'models/multinom_30.rds')

elnet_grid <- expand.grid(alpha = c(0, 0.5, 1), lambda = seq(0.001, 0.05, by = 0.01))
elnet_30 <- train(label ~ .,data = df_train30,method = "glmnet",trControl = train_control, tuneGrid = elnet_grid)
saveRDS(elnet_30, file = 'models/elnet_30.rds')

nn_grid <- expand.grid(size = c(5, 10), decay = c(0.01, 0.1, 0.5))
nn_30 <- train(label ~ ., data = df_train30, method = "nnet", trControl = train_control, tuneGrid = nn_grid)
saveRDS(nn_30, file = 'models/nnet_30.rds')

adaboost_grid <- expand.grid(maxdepth = c(5,10,15), mfinal = c(50,100,150,200), coeflearn = 'Zhu')
adaboost_30 <- train(label ~ ., data = df_train30, method = "AdaBoost.M1", trControl = train_control, tuneGrid = adaboost_grid)
saveRDS(adaboost_30, file = 'models/adaboost_30.rds')
