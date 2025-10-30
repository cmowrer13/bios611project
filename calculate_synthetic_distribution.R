library(tidyverse)
source("contact_distribution_function.R")

similar_pitches <- read_csv("derived_data/similar_pitches.csv")
similar_batters <- read_csv("derived_data/similar_batters.csv")

normalize_weights <- function(df, dist_col = "distance"){
  df %>% 
    mutate(weight_raw = 1 / (!!sym(dist_col) + 1e-6),
           weight = weight_raw / sum(weight_raw))
}

get_synthetic_distribution <- function(statcast_data,
                                       batter_name,
                                       pitcher_name,
                                       pitch_type,
                                       width = 5) {
  
  # 1. True matchup
  dist_true <- get_contact_distribution(statcast_data, batter_name, pitcher_name, pitch_type, width)
  n <- sum(dist_true$n, na.rm = TRUE)
  
  # 2. Similar pitches
  sim_p <- similar_pitches %>%
    filter(pitcher_name == !!pitcher_name, pitch_name == !!pitch_type) %>%
    normalize_weights("distance")
  
  pitch_dists <- sim_p %>%
    mutate(
      dist = map2(neighbor_pitcher_name, neighbor_pitch_name,
                  ~ get_contact_distribution(statcast_data, batter_name, .x, .y, width))
    ) %>%
    filter(!map_lgl(dist, is.null)) %>%
    mutate(n_contrib = map_dbl(dist, ~ sum(.x$n, na.rm = TRUE))) %>%
    mutate(weighted_dist = map2(dist, weight_raw, ~ mutate(.x, freq = freq * .y)))
  
  if (nrow(pitch_dists) > 0) {
    dist_pitch <- bind_rows(pitch_dists$weighted_dist) %>%
      group_by(la_bin, ev_bin) %>%
      summarise(freq = sum(freq, na.rm = TRUE), .groups = "drop")
  } else {
    dist_pitch <- dist_true %>% mutate(freq = 0)
  }
  
  n_p <- sum((pitch_dists$weight_raw) * pitch_dists$n_contrib, na.rm = TRUE)
  
  # 3. Similar batters
  sim_b <- similar_batters %>%
    filter(batter_name == !!batter_name, pitch_name == !!pitch_type) %>%
    normalize_weights("distance")
  
  batter_dists <- sim_b %>%
    mutate(
      dist = map(neighbor_batter_name,
                 ~ get_contact_distribution(statcast_data, .x, pitcher_name, pitch_type, width))
    ) %>%
    filter(!map_lgl(dist, is.null)) %>%
    mutate(n_contrib = map_dbl(dist, ~ sum(.x$n, na.rm = TRUE))) %>%
    mutate(weighted_dist = map2(dist, weight_raw, ~ mutate(.x, freq = freq * .y)))
  
  if (nrow(batter_dists) > 0) {
    dist_batter <- bind_rows(batter_dists$weighted_dist) %>%
      group_by(la_bin, ev_bin) %>%
      summarise(freq = sum(freq, na.rm = TRUE), .groups = "drop")
  } else {
    dist_batter <- dist_true %>% mutate(freq = 0)
  }
  
  n_b <- sum((batter_dists$weight_raw) * batter_dists$n_contrib, na.rm = TRUE)
  
  # 4. Combine weighted distributions
  denom <- sqrt(n) + sqrt(n_p) + sqrt(n_b)
  w_true <- sqrt(n) / denom
  w_pitch <- sqrt(n_p) / denom
  w_batter <- sqrt(n_b) / denom
  
  safe_dist <- function(d) {
    if (is.null(d)) tibble(la_bin = character(), ev_bin = character(), freq = numeric())
    else d
  }
  
  dist_true  <- safe_dist(dist_true)
  dist_pitch <- safe_dist(dist_pitch)
  dist_batter <- safe_dist(dist_batter)
  
  if (nrow(dist_true) == 0) {
    bin_ref <- if (nrow(dist_pitch) > 0) dist_pitch else dist_batter
    if (nrow(bin_ref) > 0)
      dist_true <- bin_ref %>% transmute(la_bin, ev_bin, freq = 0)
  }
  
  synthetic <- full_join(dist_true, dist_pitch, by = c("la_bin", "ev_bin"), suffix = c("", ".p")) %>%
    full_join(dist_batter, by = c("la_bin", "ev_bin"), suffix = c("", ".b")) %>%
    mutate(across(starts_with("freq"), replace_na, 0)) %>%
    mutate(freq = w_true * freq + w_pitch * freq.p + w_batter * freq.b) %>%
    transmute(la_bin, ev_bin, freq = freq / sum(freq, na.rm = TRUE))
  
  list(
    synthetic_distribution = synthetic,
    weights = c(real = w_true, pitch = w_pitch, batter = w_batter),
    n = c(n, n_p, n_b)
  )
}
