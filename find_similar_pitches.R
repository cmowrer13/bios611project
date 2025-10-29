library(RANN)
library(tidyverse)

all_pitches <- read_csv("raw_data/raw_data.csv")

pitch_profiles <- all_pitches %>% 
  filter(!pitch_name %in% c("Eephus", "Forkball", "Knuckleball", "Other", "Pitch Out", "Screwball", "Slow Curve")) %>% 
  filter(!is.na(pitch_name)) %>% 
  group_by(pitcher, pitch_name) %>% 
  summarize(across(c(release_speed, release_spin_rate, spin_axis, pfx_x, pfx_z, plate_x, plate_z),
                   mean, na.rm = T),
            n = n()) %>% 
  ungroup()

feature_cols <- c("release_speed", "release_spin_rate", "spin_axis", "pfx_x", "pfx_z", "plate_x", "plate_z")

pitch_profiles_scaled <- pitch_profiles %>%
  mutate(across(all_of(feature_cols), ~scale(.) %>% as.vector())) %>% 
  mutate(pitch_id = row_number())

feature_matrix <- as.matrix(pitch_profiles_scaled[, feature_cols])

k <- 10

nn <- nn2(data = feature_matrix, query = feature_matrix, k = k + 1)

neighbors <- as.data.frame(nn$nn.idx[, -1])
dists <- as.data.frame(nn$nn.dists[, -1])

colnames(neighbors) <- paste0("neighbor_", 1:k)
colnames(dists) <- paste0("dist_", 1:k)

neighbors <- neighbors %>%
  mutate(pitch_id = 1:nrow(.))

dists <- dists %>%
  mutate(pitch_id = 1:nrow(.))

neighbor_df <- neighbors %>%
  pivot_longer(
    cols = starts_with("neighbor_"),
    names_to = "rank",
    names_prefix = "neighbor_",
    values_to = "neighbor_id")

dist_df <- dists %>%
  pivot_longer(
    cols = starts_with("dist_"),
    names_to = "rank",
    names_prefix = "dist_",
    values_to = "distance")

neighbor_df <- left_join(neighbor_df, dist_df, by = c("pitch_id", "rank")) %>%
  mutate(rank = as.integer(rank))

neighbor_df <- neighbor_df %>%
  left_join(pitch_profiles_scaled %>% select(pitch_id, pitcher, pitch_name), by = "pitch_id") %>%
  left_join(
    pitch_profiles_scaled %>%
      select(neighbor_id = pitch_id, neighbor_pitcher = pitcher, neighbor_pitch_name = pitch_name),
    by = "neighbor_id")

player_ids <- read_csv("raw_data/player_ids.csv")

neighbor_df_named <- neighbor_df %>%
  # Join to get the main pitcher's name
  left_join(
    player_ids %>% rename(pitcher_name = player_name),
    by = c("pitcher" = "key_mlbam")
  ) %>%
  # Join again to get the neighbor pitcher's name
  left_join(
    player_ids %>%
      rename(neighbor_pitcher_name = player_name),
    by = c("neighbor_pitcher" = "key_mlbam")
  ) %>%
  select(pitcher_name, pitch_name, 
         rank,
         neighbor_pitcher_name, neighbor_pitch_name,
         distance)

write.csv(neighbor_df_named, "derived_data/similar_pitches.csv", row.names = FALSE)
