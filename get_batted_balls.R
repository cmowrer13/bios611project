library(tidyverse)

data <- read_csv("./work/raw_data/raw_data.csv")

balls_in_play <- data %>% 
  filter(description == "hit_into_play") %>% 
  arrange(game_date, at_bat_number)

write_csv(balls_in_play, "./work/derived_data/balls_in_play.csv")
