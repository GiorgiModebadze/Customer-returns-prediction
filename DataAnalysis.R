rm(list = ls())
#necessary libraries
library(tidyverse)
library(skimr)
library(psych)
library(lubridate)
setwd("../Final Assignment/BADSFinal/")
getwd()
#load both datasets
knownData = read.csv("../BADSFinal/BADS_WS1819_known.csv")
unknownData = read.csv("BADS_WS1819_unknown.csv")


#cleaning & preparing Data
knownData = knownData[-1] ## remove order id as it does not play any role
knownData$user_dob = as.Date(knownData$user_dob, format = "%Y-%m-%d")
knownData$order_date = as.Date(knownData$order_date, format = "%Y-%m-%d")
knownData$delivery_date = as.Date(knownData$delivery_date, format = "%Y-%m-%d")
knownData$user_reg_date = as.Date(knownData$user_reg_date, format = "%Y-%m-%d")
knownData$user_id = factor(knownData$user_id)
knownData$item_id = factor(knownData$item_id)
knownData$brand_id = factor(knownData$brand_id)
knownData$item_color = factor(knownData$item_color)
knownData$item_size= factor(knownData$item_size)
knownData$user_state = factor(knownData$user_state)
knownData$user_title = factor(knownData$user_title)
#Check KnowData

str(knownData)
head(knownData)
skim(knownData)

#Check ItemPrices
ggplot(knownData, aes(y = item_price)) + geom_boxplot()
quantile(knownData$item_price)
## as seen there are some outliers lets get them and if needed remove them
# need some action for outliers

# lets check if prices differ by title
ggplot(knownData, aes(x= user_title, y = item_price)) + geom_boxplot() + 
  facet_wrap(~ return)

#
group_by(knownData, user_title, return) %>% summarise(price = mean(item_price))

# items with higher prices are mostly returned

#check users age[]

library(data.table)

plot(table(year(knownData$user_dob)))

filter(knownData, year(user_dob) < 2000 , year(user_dob) > 1930 ) %>% 
  dplyr::select(user_dob) %>% mutate(user_dob = year(user_dob)) %>%
  ggplot(aes(x = user_dob)) + geom_density() + theme_minimal()

## dob seems very normally distributed

ggplot(knownData, aes(x = item_price)) + geom_density() + scale_x_continuous() +
  facet_wrap(~return) 

## check sizes

group_by(knownData, item_size) %>% summarize(count = n()) %>% arrange(desc(count)) %>%
  filter(count < 100) 

## check average dilivery time
dplyr::select(knownData,return,user_state, user_title, delivery_date, order_date) %>% 
  mutate( delivery_time = as.numeric(delivery_date - order_date)) %>% 
  filter(!is.na(delivery_time), delivery_time > 0, delivery_time<50) %>% 
  ggplot(aes(y = delivery_time)) + geom_boxplot() + facet_wrap(~ return)

## we have some data where order date is more than delivery date and some extreme
## values for delivery time in general

## lets check item_prices by regions

ggplot(knownData, aes(x= user_state, y = item_price)) + geom_boxplot() + coord_flip()

## returns by regions
prop.table(table(knownData$return, knownData$user_state),2)

skim(knownData)

## lets check return perc

table(knownDataClear$return, knownDataClear$user_title)


##
filter(knownData, is.na(delivery_date))

## lets start clearing our data and preparing for the model
knownDataClear = filter(knownData, !is.na(delivery_date))
knownDataClear = filter(knownDataClear, order_date < delivery_date)

## lets remove user_dob as it is normally distibuted and plays role on return
knownDataClear = dplyr::select(knownDataClear, order_date, delivery_date, item_id, item_size,
                               item_color, brand_id, item_price, user_id, user_title, user_state,
                               return)

## lets move Company and Families in not reported section as they should not be playing huge role
table(knownDataClear$return, knownDataClear$user_title)
knownDataClear$user_title = as.character(knownDataClear$user_title)

knownDataClear$user_title = ifelse(knownDataClear$user_title %in% 
                                     c("Company","Family","not reported"), "not reported",
                                  knownDataClear$user_title ) 
knownDataClear$user_title = factor(knownDataClear$user_title)

levels(knownDataClear$user_title)

table(knownDataClear$return, knownDataClear$user_title)

group_by(knownData,month= month(order_date)) %>% summarise( return_rate =  sum(return)/n()) %>%
  ggplot(aes(x = month, y = return_rate )) + geom_line() + theme_minimal()

## lets reduce number of colors
knownDataClear$item_color = as.character(knownDataClear$item_color)

excesscolors = group_by(knownDataClear, item_color) %>%dplyr:: summarise(count = n())%>% 
  filter(count < nrow(knownDataClear)* 0.001)

knownDataClear$item_color = ifelse(knownDataClear$item_color %in%
                                     excesscolors$item_color, "Other", knownDataClear$item_color)


knownDataClear$item_color = as.factor(knownDataClear$item_color)

table(knownDataClear$item_color)

## reduce number of sizes with same approach
knownDataClear$item_size = as.character(knownDataClear$item_size)
knownDataClear$item_size = toupper(knownDataClear$item_size)

excesssize = group_by(knownDataClear, item_size) %>%dplyr:: summarise(count = n())%>% 
  filter(count < nrow(knownDataClear)* 0.001) %>% arrange(desc(count))

sum(excesssize$count)

knownDataClear$item_size = ifelse(knownDataClear$item_size %in%
                                     excesssize$item_size, "Other", knownDataClear$item_size)

knownDataClear$item_size = as.factor(knownDataClear$item_size)

table(knownDataClear$item_size)


## 
skim(knownDataClear)

## check users who return most
knownDataClear$return = as.numeric(knownDataClear$return)

usersWithHugeReturns = group_by(knownDataClear, user_id) %>% summarise(returns= sum(return), total = n()) %>% 
  mutate(returnPRC = returns/total) %>% filter(returnPRC > 0.8, total > 5) %>% arrange(desc(returns)) 
usersWithLowReturns = group_by(knownDataClear, user_id) %>% summarise(returns= sum(return), total = n()) %>% 
  mutate(returnPRC = returns/total) %>% filter(returnPRC < 0.1, total > 5) %>% arrange(desc(returns)) 

knownDataClear =  filter(knownDataClear, !(user_id  %in% usersWithHugeReturns$user_id))


skim(knownDataClear)

# Calculate the z-score with the function we created earlier for standardization
standardize <- function(x){
  mu <- mean(x)
  std <- sd(x)
  result <- (x - mu)/std
  return(result)
}

knownDataClear$item_price = standardize(knownDataClear$item_price)


## Weight of Evidence to remove too many Factors
library(klaR)
library(InformationValue)
library(Information)
library(gridExtra)
library(woe)


knownDataClear

