library(RANN)
library(tidyverse)

all_pitches <- read_csv("raw_data/raw_data.csv") %>% 
  filter(!pitch_name %in% c("Eephus", "Forkball", "Knuckleball", "Other", "Pitch Out", "Screwball", "Slow Curve")) %>% 
  filter(!is.na(pitch_name))

bip_profiles <- all_pitches %>%
  group_by(batter, pitch_name) %>%
  summarize(
    n_bip = n(),
    mean_la = mean(launch_angle, na.rm = TRUE),
    sd_la   = sd(launch_angle, na.rm = TRUE),
    mean_ev = mean(launch_speed, na.rm = TRUE),
    sd_ev   = sd(launch_speed, na.rm = TRUE),
    .groups = "drop"
  ) %>% 
  filter(n_bip > 20) %>% 
  filter(complete.cases(.))

whiff_event <- c("swinging_strike", "swinging_strike_blocked")
strike_event <- 1:9
swing_event <- c("foul", "foul_tip", "hit_into_play", "swinging_strike", "swinging_strike_blocked")

plate_profiles <- all_pitches %>%
  group_by(batter, pitch_name) %>%
  summarize(
    n_pitches = n(),
    # pitches outside the zone
    n_outside_zone = sum(!(zone %in% strike_event), na.rm = TRUE),
    swings_outside_zone = sum((description %in% swing_event) & !(zone %in% strike_event), na.rm = TRUE),
    # chase rate: swings on pitches outside zone / pitches outside zone
    chase_rate = ifelse(n_outside_zone > 0, swings_outside_zone / n_outside_zone, NA_real_),
    # whiff rate: swinging strikes / total swings
    total_swings = sum(description %in% swing_event, na.rm = TRUE),
    n_whiff = sum(description %in% whiff_event, na.rm = TRUE),
    whiff_rate = ifelse(total_swings > 0, n_whiff / total_swings, NA_real_),
    .groups = "drop"
  ) %>% 
  filter(n_pitches > 20) %>% 
  filter(complete.cases(.))

batter_profiles <- plate_profiles %>%
  merge(bip_profiles, by = c("batter", "pitch_name")) %>% 
  select(batter, pitch_name, mean_la, sd_la, mean_ev, sd_ev, chase_rate, whiff_rate, n_pitches)

feature_cols <- c("mean_la", "sd_la", "mean_ev", "sd_ev", "chase_rate", "whiff_rate")

batter_profiles_scaled <- batter_profiles %>%
  mutate(across(all_of(feature_cols), ~scale(.) %>% as.vector())) %>% 
  mutate(batter_id = row_number())

feature_matrix <- as.matrix(batter_profiles_scaled[, feature_cols])

k <- 10

neighbor_df <- batter_profiles_scaled %>%
  group_split(pitch_name) %>%
  map_dfr(function(df_pitch) {
    
    feature_matrix <- as.matrix(df_pitch[, feature_cols])
    
    # Use nn2 to find neighbors within this pitch type
    nn <- nn2(data = feature_matrix, query = feature_matrix, k = min(k + 1, nrow(df_pitch)))
    
    neighbors <- as.data.frame(nn$nn.idx[, -1])
    dists <- as.data.frame(nn$nn.dists[, -1])
    
    colnames(neighbors) <- paste0("neighbor_", 1:(ncol(neighbors)))
    colnames(dists) <- paste0("dist_", 1:(ncol(dists)))
    
    neighbors <- neighbors %>%
      mutate(batter_id = df_pitch$batter_id)
    
    dists <- dists %>%
      mutate(batter_id = df_pitch$batter_id)
    
    neighbor_df <- neighbors %>%
      pivot_longer(
        cols = starts_with("neighbor_"),
        names_to = "rank",
        names_prefix = "neighbor_",
        values_to = "neighbor_local_id"
      )
    
    dist_df <- dists %>%
      pivot_longer(
        cols = starts_with("dist_"),
        names_to = "rank",
        names_prefix = "dist_",
        values_to = "distance"
      )
    
    neighbor_df <- neighbor_df %>%
      left_join(dist_df, by = c("batter_id", "rank")) %>%
      mutate(rank = as.integer(rank)) %>%
      mutate(neighbor_id = df_pitch$batter_id[neighbor_local_id]) %>%
      select(batter_id, rank, neighbor_id, distance)
    
    neighbor_df
  })

# Add names back in for readability
neighbor_df <- neighbor_df %>%
  left_join(
    batter_profiles_scaled %>% select(batter_id, batter, pitch_name),
    by = "batter_id"
  ) %>%
  left_join(
    batter_profiles_scaled %>% 
      select(neighbor_id = batter_id,
             neighbor_player = batter,
             neighbor_pitch_name = pitch_name),
    by = "neighbor_id"
  ) %>%
  select(batter, pitch_name, rank, neighbor_player, neighbor_pitch_name, distance)

player_ids <- read_csv("raw_data/player_ids.csv")

neighbor_df_named <- neighbor_df %>%
  # Join to get the main pitcher's name
  left_join(
    player_ids %>% rename(batter_name = player_name),
    by = c("batter" = "key_mlbam")
  ) %>%
  # Join again to get the neighbor pitcher's name
  left_join(
    player_ids %>%
      rename(neighbor_batter_name = player_name),
    by = c("neighbor_player" = "key_mlbam")
  ) %>%
  select(batter_name, pitch_name, 
         rank,
         neighbor_batter_name, neighbor_pitch_name,
         distance)

write.csv(neighbor_df_named, "derived_data/similar_batters.csv")
