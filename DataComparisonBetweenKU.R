knownData$delivery_date = as.Date(knownData$delivery_date)
unknownData$delivery_date = as.Date(unknownData$delivery_date)
knownData$order_date = as.Date(knownData$order_date)
unknownData$order_date = as.Date(unknownData$order_date)


dplyr::filter(knownData, delivery_date > "2006-05-02") %>%
    ggplot(aes(x= delivery_date)) + geom_histogram(stat="count")

# suspicious fact. We have a lot of NAs in date and date 1994-12-31 seems something odd
count(knownData, delivery_date) %>% arrange(desc(n))

# lets take a look at NAs first
# lets see if the items were delivered at all or if there is something with retuurn
dplyr::filter(knownData, is.na(delivery_date)) %>% group_by(return) %>% summarise(count = n())

# strangely enough all the items that has NA as delivery date were not returned.

# lets check if we have any NAs in our test data
dplyr::filter(unknownData,is.na(delivery_date)) # this is the case
count(unknownData, delivery_date) %>% arrange(desc(n))

# lets leave NAs as it is, assumin this items wont be reurned. we will see how algorithm
# will interpret it
dplyr::filter(unknownData, delivery_date > "2006-05-02") %>%
  ggplot(aes(x= delivery_date)) + geom_histogram(stat="count")

# lets check 1994-12-31 as it is only anomaly

dplyr::filter(knownData, order_date > delivery_date) %>% count(delivery_date)
dplyr::filter(unknownData, order_date > delivery_date) %>% count(delivery_date)

# it seems strange that this date is only one
# there should not be a problem with order date at first glance
dplyr::filter(knownData, order_date > delivery_date) %>% ggplot(aes(x = order_date))+
  geom_histogram()
dplyr::filter(unknownData, order_date > delivery_date) %>% ggplot(aes(x = order_date))+
  geom_histogram()

# lets check if it has any impact on return status
dplyr::filter(knownData, order_date > delivery_date) %>% count(return)
dplyr::filter(knownData, order_date > delivery_date) 

# check user registrationdate
knownData%>% ggplot(aes(x = user_reg_date))+
  geom_histogram()
unknownData%>% ggplot(aes(x = user_reg_date))+
  geom_histogram()

# user_dob
knownData %>% count(user_dob) %>% arrange(desc(n))
unknownData %>% count(user_dob) %>% arrange(desc(n))

# three values stand out
# 1 ""          5119
# 2 1900-11-21   424
# 3 1949-11-21   235

knownData

filter(knownData, user_dob =="") %>% count(return)
filter(unknownData, user_dob =="") %>% count(return)

count(knownData, brand_id) %>% filter(n > 500) %>% arrange(desc(n))
count(knownData, item_id) %>% filter(n > 250)%>% arrange(desc(n))



# check users

