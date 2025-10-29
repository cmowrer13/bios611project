library(baseballr)

player_ids <- chadwick_player_lu() %>% 
  select(key_mlbam, name_last, name_first) %>% 
  filter(!is.na(key_mlbam))

players <- player_ids %>% 
  mutate(player_name = paste(name_first, name_last)) %>% 
  select(key_mlbam, player_name)

write.csv(players, "raw_data/player_ids.csv")
