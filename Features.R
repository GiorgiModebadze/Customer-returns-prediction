library(tidyverse)
library(lubridate)
library(skimr)
library(data.table)
library(mlr)
library(caret)
library(nnet)
library(ModelMetrics)

source("CleanAndFeatures.R")

knownData = read.csv(file = "../BADSFinal/BADS_WS1819_known.csv")
unknownData = read.csv(file ="../BADSFinal/BADS_WS1819_unknown.csv")


count(knownData,item_size)

## move to correct format
knownData = cleanData(knownData)
unknownData = cleanData(unknownData)
unknownData
knownData$return = as.factor(knownData$return)

str(knownData)
str(unknownData)

head(knownData,20)
head(unknownData,10)

selectedData = dplyr::select(knownData,item_size, item_color, item_price, user_title, user_state,
                      return,purchase, na_delivery_date, delivery_days, user_age, user_birth_day,
                      user_birth_month, user_birth_year, user_timeInDays, order_year,
                      order_month, order_day, reg_day, reg_month,reg_year,
                      brandPopularity,item_type,size_origin)
 

selectedDataUk = dplyr::select(unknownData,item_size, item_color, item_price, user_title, user_state,
                               purchase, na_delivery_date, delivery_days, user_age, user_birth_day,
                               user_birth_month, user_birth_year, user_timeInDays, order_year,
                               order_month, order_day, reg_day, reg_month,reg_year,
                               brandPopularity,item_type,size_origin)






