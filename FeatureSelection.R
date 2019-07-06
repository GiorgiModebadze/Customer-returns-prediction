library(leaps) 
library(MASS) 
library(caret) 
library(hmeasure) 
library(randomForest)
library(xgboost)
library(mlr)

idx.test <- createDataPartition(y = selectedData$return, p = 0.3, list = FALSE)
ts <- selectedData[idx.test, ]

idx.val <- createDataPartition(y = selectedData$return[-idx.test], p = 0.35, list = FALSE) 
val <- selectedData[-idx.test, ][idx.val,]
tr <- selectedData[-idx.test, ][-idx.val,] # training set
head(selectedData)
auc <- rep(NA, 20)
varn <- colnames(selectedData)
varn

for (i in 1:length(varn)){
  # Add the (arbitrarily) first i variables in the dataset
  Formula <- formula(paste("return ~ ", paste(varn[1:i], collapse=" + "))) # Train a logit model
  lm <- glm(Formula,tr,family="binomial")
  yhat <- predict(lm, val[,c(1:i,15)],type="response")
  # Calculate the AUC score on the test data
  h <- HMeasure(true.class = as.numeric(val$return==1), scores = yhat)
  auc[i]<- h$metrics["AUC"] }
plot(unlist(auc),type="l")


basic <- glm(return~1, data=tr,family = "binomial")
full <- glm(return~., data=tr,family = "binomial")

glm_stepwise <- stepAIC(basic, scope = list(lower = basic, upper = full), 
                        direction = "both", trace = TRUE, steps = 100)


# ls 12

data <- mlr::createDummyFeatures(selectedData, target = "return")
idx.test <- createDataPartition(y = data$return, p = 0.2, list = FALSE)
ts <- data[idx.test, ] # test set
tr <- data[-idx.test, ] # training set

logit <- glm(return~., data = tr, family = binomial(link = "logit"))
logit_nonlinear <- glm(return~.+I(item_price^2)+I(item_price^3), data = tr,
                       family = binomial(link= "logit"))

summary(logit)
