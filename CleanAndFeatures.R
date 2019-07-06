library(tidyverse)
library(lubridate)

# formats data variables
cleanTimeVariables = function(data){

  # converts date into date format
  data$user_dob = as.Date(data$user_dob, format = "%Y-%m-%d")
  data$order_date = as.Date(data$order_date, format = "%Y-%m-%d")
  data$delivery_date = as.Date(data$delivery_date, format = "%Y-%m-%d")
  data$user_reg_date = as.Date(data$user_reg_date, format = "%Y-%m-%d")
  
  # generates mean delivery time
  meanDeliveryTime = filter(data, !is.na(delivery_date) & delivery_date >= order_date) %>% 
    summarise(total = n(), range = max(delivery_date - order_date) - min(delivery_date - order_date),
            meanDeliveryTime = as.integer(mean(delivery_date - order_date)))
  
  # generate new time related featuers. clean old ones
  data = mutate(data, 
                
    na_delivery_date = if_else(is.na(delivery_date),1,0),
    
    delivery_date = if_else(delivery_date < order_date | is.na(delivery_date),
                           order_date + meanDeliveryTime$meanDeliveryTime, delivery_date),
    
    delivery_days = as.integer(delivery_date-order_date),
    
    user_dob = if_else(is.na(user_dob) | user_dob < "1945-01-01" | user_dob > "2001-01-01",
                      median(data$user_dob,na.rm = TRUE),user_dob),
    
    user_age = lubridate::year(Sys.Date()) - lubridate::year(user_dob),
    
    user_birth_day = lubridate::day(user_dob),
    
    user_birth_month = lubridate::month(user_dob),
    
    user_birth_year = lubridate::year(user_dob),
    
    user_timeInDays =as.numeric(Sys.Date() - user_reg_date),
    
    order_year = lubridate::year(order_date),
    
    order_month = lubridate::month(order_date),
    
    order_day = lubridate::day(order_date),
    
    reg_day = lubridate::day(user_reg_date),
    
    reg_month = lubridate::month(user_reg_date),
    
    reg_year = lubridate::year(user_reg_date),
    
    user_reg_date = NULL,
    delivery_date = NULL,
    user_dob = NULL,
    order_date = NULL
  )

  return(data)
}


# cleans colors 
cleanColor = function(data){
  # correct typos 
  data = data %>% mutate(item_color = case_when(item_color == "blau" ~ "blue",
                                              item_color == "brwon" ~ "brown",
                                              item_color == "oliv" ~ "olive",
                                              TRUE ~ as.character(item_color)))
  
  # make smalles amount of colors as others
  maincolors = group_by(data, item_color) %>%dplyr:: summarise(count = n())%>%
    filter(count > nrow(data)* 0.005)
  
  data$item_color = ifelse(data$item_color %in% maincolors$item_color, as.character(data$item_color), "other" )
  data$item_color = as.factor(data$item_color)
  
  return(data)
}

# cleans sizes and generates categories
cleanSize = function(data){
  # bringing al sizes to lower caas
  data$item_size = tolower(data$item_size)
  
  # create new variable type
  
  data = data %>% mutate(item_type = case_when(
    # special cases
    grepl("[unsized]", item_size) ~ "TypeUnsized",
    grepl("[+]", item_size) ~ "TypeHalf",
    grepl("[0-9]{3}", item_size) ~ "TypeBigNumber",
    # general case
    grepl("[a-z]", item_size) ~ "TypeChar",
    # number sizes
    grepl("[0-9]",item_size) ~ "TypeNumeric",
    TRUE ~ as.character(item_size)
  )) %>%
    
  mutate(item_size = gsub("\\+","",item_size),
   item_size_numeric =
     ifelse(item_type == "TypeNumeric" | item_type == "TypeHalf" ,as.integer(item_size),11111),
   size_origin = case_when(
     item_size_numeric == 11111 ~ "unknown",
     item_size_numeric > 16 & item_size_numeric < 54 ~ "EU",
     item_size_numeric >= 54 ~ "Other",
     item_size_numeric <= 16 ~ "US",
     TRUE ~ "Something went wrong"),
   item_size = case_when(
     item_size_numeric != 11111 & item_size_numeric >= 54 ~ "unknown",
     size_origin == "EU" & item_size_numeric >= 43 ~ "l",
     size_origin == "EU" & item_size_numeric < 43 & item_size_numeric > 37  ~ "m",
     size_origin == "EU" & item_size_numeric <= 37  ~ "s",
     size_origin == "US" & item_size_numeric >= 10  ~ "l",
     size_origin == "US" & item_size_numeric < 10 & item_size_numeric > 7  ~ "m",
     size_origin == "US" & item_size_numeric <= 7  ~ "s",
     item_type == "TypeBigNumber" ~ "Other",
     item_size == "xs" ~ "s",
     item_size == "xxxl" ~ "xxl",
     TRUE ~ item_size)) %>% select(-item_size_numeric)
  
  return(data)
}

frequencyFeatuers = function(data){
  
  # makes brands by their popularity
  brandCounts = data %>% count(brand_id) %>% mutate(brandPopularity = case_when(
    n <= 1 ~ "OneTime",
    n > 1 & n <= 10 ~ "lowest",
    n > 10 & n <= 50 ~ "low",
    n > 50 & n <= 100 ~ "low+",
    n > 100 & n <= 200 ~ "medium-",
    n > 200 & n <= 500 ~ "medium",
    n > 500 & n <= 1000 ~ "medium+",
    n > 1000 & n <= 5000 ~ "large",
    TRUE ~ "top"
  ))
  
  data = data %>% mutate(brandPopularity = as.factor(ifelse(
    brand_id %in% brandCounts$brand_id, brandCounts$brandPopularity, 0)))
  
  # makes items by their popularity
  
  itemCounts = data %>% count(item_id) %>% mutate(itemPopularity = case_when(
    n == 1 ~ "oneTime",
    n >= 1 & n <= 5 ~ "lowest",
    n > 5 & n <= 10 ~ "low",
    n > 10 & n <= 20 ~ "low+",
    n > 20 & n <= 50 ~ "medium-",
    n > 50 & n <= 100 ~ "medium",
    n > 100 & n <= 200 ~ "medium+",
    n > 200 & n <= 500 ~ "large",
    TRUE ~ "Top"
  ))
  
  data = data %>% mutate(itemPopularity = as.factor(ifelse(
    item_id %in% itemCounts$item_id, itemCounts$itemPopularity, 0)))
  
  # assigns users its their activity
  
  userActivity = data %>% count(user_id) %>% mutate(userActivity = case_when(
    n == 1 ~ "oneTime",
    n >= 1 & n <= 5 ~ "low",
    n > 5 & n <= 10 ~ "low+",
    n > 10 & n <= 20 ~ "medium",
    n > 20 & n <= 30 ~ "medium+",
    n > 30 & n <= 50 ~ "high",
    TRUE ~ "Top"
  ))
  
  data = data %>% mutate(userActivity = as.factor(ifelse(
    user_id %in% userActivity$user_id, userActivity$userActivity, 0)))
  
  return(data)
}

userTotalPurchase = function(data){
  userTotalPurchase = data %>% group_by(user_id) %>% summarise(purchase = sum(item_price)) 
  data = left_join(data,userTotalPurchase, by = "user_id")
  
  return(data)
}

## final function for data cleaning and feature engineering 
cleanData = function(data){
  data = userTotalPurchase(data)
  data = cleanTimeVariables(data)
  data = cleanColor(data)
  data = frequencyFeatuers(data)
  data = cleanSize(data)
  
  #drop some columns
  data$user_id = NULL
  data$item_id = NULL
  data$brand_id = NULL
  data$na_delivery_date = as.factor(data$na_delivery_date)
  data$item_size = as.factor(data$item_size)
  data$item_type = as.factor(data$item_type)
  data$size_origin = as.factor(data$size_origin)
  return(data)
}

