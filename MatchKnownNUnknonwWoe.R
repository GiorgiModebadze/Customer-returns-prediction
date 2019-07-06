library(tidyverse)
library(data.table)
head(woeDdata)
head(unknownData)
head(woeData)
summary(woeModel$woe)

unknownWoeData = unknownData

# lets check item_id 
item_weights = as.data.table(woeModel$woe$item_id,keep.rownames = T)
item_size = as.data.table(woeModel$woe$item_size,keep.rownames = T)
item_color = as.data.table(woeModel$woe$item_color, keep.rownames = T)
brand_id = as.data.table(woeModel$woe$brand_id, keep.rownames = T)
user_id = as.data.table(woeModel$woe$user_id, keep.rownames = T)
user_title = as.data.table(woeModel$woe$user_title, keep.rownames = T)
user_state = as.data.table(woeModel$woe$user_state, keep.rownames = T)
order_month = as.data.table(woeModel$woe$order_month, keep.rownames = T)


unknownWoeData$woe_item_id = ifelse(unknownWoeData$item_id %in% item_weights$V1,item_weights$V2,0 )
unknownWoeData$woe_item_size = ifelse(unknownWoeData$item_size %in% item_size$V1,item_size$V2,0 )
unknownWoeData$woe_item_color = ifelse(unknownWoeData$item_color %in% item_color$V1,item_color$V2,0 )
unknownWoeData$woe_brand_id = ifelse(unknownWoeData$brand_id %in% brand_id$V1, brand_id$V2,0 )
unknownWoeData$woe_user_id = ifelse(unknownWoeData$user_id %in% user_id$V1, user_id$V2,0)
unknownWoeData$woe_user_title = ifelse(unknownWoeData$user_title %in% user_title$V1,user_title$V2,0 )
unknownWoeData$woe_user_state = ifelse(unknownWoeData$user_state %in% user_state$V1,user_state$V2,0 )
unknownWoeData$woe_order_month = ifelse(unknownWoeData$order_month %in% order_month$V1,user_state$V2,0 )

head(unknownWoeData)
head(woeData)

unknownWoeData$order_date = as.numeric(unknownWoeData$order_date)
unknownWoeData$delivery_date = as.numeric(unknownWoeData$delivery_date)
unknownWoeData$user_reg_date = as.numeric(unknownWoeData$user_reg_date)
unknownWoeData$item_id = NULL
unknownWoeData$item_size = NULL
unknownWoeData$item_color = NULL
unknownWoeData$brand_id = NULL
unknownWoeData$user_id = NULL
unknownWoeData$user_state = NULL
unknownWoeData$user_title = NULL
unknownWoeData$order_month = NULL

head(unknownWoeData)
unknownWoeData = unknownWoeData[-1]
