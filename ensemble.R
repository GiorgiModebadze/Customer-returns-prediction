
library(mlr)
library(caret)
idx.train <- createDataPartition(y = selectedData$return, p = 0.8, list = FALSE)

tr_raw <- selectedData[idx.train, ] # training set
ts_raw <-  selectedData[-idx.train, ] # test set (drop all observations with train indeces)

library(h2o)
h2o.init(nthreads = -1)


# Import a sample binary outcome train/test set into H2O
train = as.h2o(tr_raw)
test = as.h2o(ts_raw)

y <- "return"
x <- setdiff(names(train), y)

train[,y] <- as.factor(train[,y])
test[,y] <- as.factor(test[,y])

nfolds <- 5


my_gbm <- h2o.gbm(x = x,
                  y = y,
                  training_frame = train,
                  distribution = "bernoulli",
                  ntrees = 450,
                  max_depth = 10,
                  min_rows = 2,
                  learn_rate = 0.05,
                  nfolds = nfolds,
                  fold_assignment = "Modulo",
                  keep_cross_validation_predictions = TRUE,
                  seed = 1)


my_rf <- h2o.randomForest(x = x,
                          y = y,
                          training_frame = train,
                          ntrees = 1000,
                          nfolds = nfolds,
                          fold_assignment = "Modulo",
                          keep_cross_validation_predictions = TRUE,
                          seed = 1)

ensemble <- h2o.stackedEnsemble(x = x,
                                y = y,
                                training_frame = train,
                                model_id = "my_ensemble_binomial",
                                base_models = list(my_gbm, my_rf))


perf <- h2o.performance(ensemble, newdata = test)

perf_gbm_test <- h2o.performance(my_gbm, newdata = test)
perf_rf_test <- h2o.performance(my_rf, newdata = test)
baselearner_best_auc_test <- max(h2o.auc(perf_gbm_test), h2o.auc(perf_rf_test))
ensemble_auc_test <- h2o.auc(perf)
print(sprintf("Best Base-learner Test AUC:  %s", baselearner_best_auc_test))
print(sprintf("Ensemble Test AUC:  %s", ensemble_auc_test))



