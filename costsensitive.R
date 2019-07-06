library(caret)


dataDummy = mlr::createDummyFeatures(selectedData, target = "return")
idx.train <- caret::createDataPartition(y = dataDummy$return, p = 0.75, list = FALSE)

train_data <- dataDummy[idx.train, ] 
test_data <- dataDummy[-idx.train, ]


std.values <- caret::preProcess(train_data, method = c("center", "scale"))
tr <- predict(std.values, newdata = train_data)
ts <- predict(std.values, newdata = test_data) 
modelLib <- list()
pred <- list()

modelLib[["standard"]] <- glm(return~., data = tr, family = binomial(link = "logit"))
pred[["standard"]] <- predict(modelLib[["standard"]], newdata = ts, type = "response")

caret::confusionMatrix(factor(pred[["standard"]] >= 0.5,
                              labels = c("0", "1")), as.factor(ts$return), 
                       positive = "1")$table

# 0.5 · 5 · −(3 + 0.1 · itemvalue)
# 0.5 · −itemvalue
class.weights <- round(ifelse(tr$return == "0", (0.5*train_data$item_price), 
                              0.5*5*(3+0.1*train_data$item_price)))

class.weights2 <- round(ifelse(tr$return == "1", (0.5*train_data$item_price), 
                              0.5*5*(3+0.1*train_data$item_price)))
cbind(train_data$return,train_data$item_price,class.weights,class.weights2)

modelLib[["weighted"]] <- glm(return~., data = tr, family = binomial(link = "logit"), 
                              weights = class.weights)
pred[["weighted"]] <- predict(modelLib[["weighted"]], newdata = ts, type = "response")


caret::confusionMatrix(factor(pred[["weighted"]] >= 0.5, 
                              labels = c("0", "1")), as.factor(ts$return), 
                       positive = "1")$table

pred.tr <- predict(modelLib[["standard"]], newdata = tr, type = "response")


decision_costs <- function(p_return, target, cutoff) {
  ctab <- caret::confusionMatrix( factor(p_return >= cutoff, 
                                         levels = c(FALSE, TRUE),
                                         labels = c("0", "1") ), 
                                  as.factor(target), positive = "1")$table

  decision_costs <- 1 * ctab[2,1] + 2 * ctab[1,2]
  return(decision_costs)
}


p <- seq(0,1,0.05) 
overall_cost <- numeric()

for(i in seq_along(p)){
  overall_cost[i] <- decision_costs(pred.tr, tr$return, p[i]) }

opt_cutoff <- p[which.min(overall_cost)]
opt_cutoff
wg1 = 0.5*train_data$item_price
wg2 = 0.5*5*(3+0.1*train_data$item_price)
weightBayas = wg1 / (wg1 + wg2)

caret::confusionMatrix(factor(pred[["weighted"]] >= opt_cutoff, 
                              labels = c("0", "1")), as.factor(ts$return), 
                       positive = "1")$table

costs <- sapply(c(opt_cutoff, 0.5), function(x) decision_costs(pred[["standard"]], ts$return, x))
costs


#######
prop.table(caret::confusionMatrix(factor(pred$xgb$data$prob.0 >= opt_cutoff, 
                              labels = c("0", "1")), as.factor(test_data$return), 
                       positive = "1")$table)


AveragePredictions = read_csv("~/Desktop/FinalAUC.csv")
item_price = selectedDataUk$item_price
unknownDataCosts = cbind(AveragePredictions, item_price)
unknownDataCosts

costFalseNegative = 0.5 * -item_price
costFalsePositive = 0.5 * 5 * -(3 + 0.1 * item_price)

unknownDataCosts$optimalRatio = costFalseNegative / (costFalsePositive + costFalseNegative)

unknownDataCosts = unknownDataCosts %>% mutate(final_prediction = if_else(optimalRatio>return,0,1)) %>%
  select(order_item_id, warning = final_prediction )
write_csv(unknownDataCosts,"~/Desktop/final_predictions.csv")

