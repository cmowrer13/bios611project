library(tidyverse)
library(baseballr)

start_char <- "2025-03-18"
end_char <- "2025-09-28"

start <- as.Date(start_char)
end <- as.Date(end_char)

date_seq = seq(start, end, by = "days")

date_char <- format(date_seq, "%Y-%m-%d")

data <- statcast_search(
  start_date = start_char,
  end_date = start_char) %>% 
  filter(game_type == "R")

for (date in date_char[-1]){
  data_new <- statcast_search(
    start_date = date,
    end_date = date) %>% 
    filter(game_type == "R")
  
  data <- rbind(data, data_new)
}

write_csv(data, "./work/raw_data/raw_data.csv")
