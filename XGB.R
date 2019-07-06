library(caret) 
library(mlr)
library(xgboost)

set.seed(123)
dataDummy = mlr::createDummyFeatures(selectedData, target = "return")
idx.train <- caret::createDataPartition(y = dataDummy$return, p = 0.75, list = FALSE)

train_data <- dataDummy[idx.train, ] 
test_data <- dataDummy[-idx.train, ]

colnames(train_data)
colnames(test_data)
head(train_data,10)
head(test_data, 10)
summary(train_data$return)

task <- makeClassifTask(data = train_data, target = "return", positive = "1")


xgb.learner <- makeLearner("classif.xgboost", predict.type = "prob",
                           par.vals = list("verbose" = 0,
                                           "early_stopping_rounds"=10))

xgb.parms <- makeParamSet(
  makeNumericParam("eta", lower = 0.001, upper = 0.9),
  makeIntegerParam("nrounds", lower=10, upper=1000), 
  makeIntegerParam("max_depth", lower=2, upper=100), 
  makeDiscreteParam("gamma", values = 1),
  makeDiscreteParam("colsample_bytree", values = 1), 
  makeDiscreteParam("min_child_weight", values = 1),
  makeDiscreteParam("subsample", values = 0.5)
)

tuneControl <- makeTuneControlRandom(maxit=500, tune.threshold = FALSE)

rdesc <- makeResampleDesc(method = "CV", iters = 500, stratify = TRUE)


library("parallelMap")
library(parallel)
parallelStartSocket(2, level = "mlr.tuneParams")
set.seed(123)

RNGkind("L'Ecuyer-CMRG")
clusterSetRNGStream(iseed = 1234567)
xgb.tuning <- tuneParams(xgb.learner, task = task, resampling = rdesc,
                         par.set = xgb.parms, control = tuneControl, measures = mlr::auc)
parallelStop()

xgb.learner <- setHyperPars(xgb.learner, par.vals = c(xgb.tuning$x, "verbose" = 0))

model_library <- list()

model_library[["xgb"]] <- mlr::train(xgb.learner, task = task)

rf.learner <- makeLearner("classif.randomForest",
                          predict.type = "prob", # prediction type needs to be specified for the
                          par.vals = list(
                            "mtry" = 10, "sampsize" = 1000, "ntree" = 700, "replace" = TRUE, "importance" = FALSE,
                            "nodesize" = 300))


model_library[["rf"]] <- mlr::train(rf.learner, task = task)

pred <- sapply(model_library, predict, newdata = test_data, simplify=FALSE) 
auc <- sapply(pred, mlr::performance, measures = mlr::auc)
pred$xgb$data
auc

## prediction

dummyUnknown = mlr::createDummyFeatures(selectedDataUk)

colnames(dummyUnknown)


Test1 = predict(model_library[["rf"]],newdata = dummyUnknown)
Test2 = predict(model_library[["xgb"]],newdata = dummyUnknown)

as.data.frame(Test2$data$prob.1)
as.data.frame(predictionNN$p1)

two = cbind(as.data.frame(predictionNN$p1),as.data.frame(Test2$data$prob.1))



means = apply(two,1,mean)
means = as.data.table(means)
Fdata = cbind(order_item_id = unknownData$order_item_id, means)
Fdata

write.csv(dplyr::select(as.tibble(Fdata), order_item_id, return = means), "~/Desktop/FinalAUC.csv",quote = F, row.names = F)


