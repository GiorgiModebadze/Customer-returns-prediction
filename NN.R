#giorgi.modebadze@hu-berlin.de


library(mlr)
library(caret)
library(tidyverse)
library(nnet)
library(ModelMetrics)
library("NeuralNetTools")


idx.train <- createDataPartition(y = selectedData$return, p = 0.8, list = FALSE)

tr_raw <- selectedData[idx.train, ] # training set
ts_raw <-  selectedData[-idx.train, ] # test set (drop all observations with train indeces)

library(h2o)
colnames(tr_raw[-5])
h2o.shutdown(prompt=F)
h2o.init(nthreads = -1)
train = as.h2o(tr_raw)
test = as.h2o(ts_raw)

predictionData = as.h2o(selectedDataUk)

model = h2o.deeplearning(x=colnames(tr_raw[-5]),
                         y = "return",
                         training_frame = train)

model

predictionNN = predict(model,predictionData)

head(predictionNN$p1,20)
