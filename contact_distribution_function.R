get_contact_distribution <- function(statcast_data, batter_name, pitcher_name, pitch_type, width = 5) {
  
  require(tidyverse)
  
  batter_id <- player_ids %>%
    filter(player_name == batter_name) %>%
    pull(key_mlbam)
  
  pitcher_id <- player_ids %>%
    filter(player_name == pitcher_name) %>%
    pull(key_mlbam)
  
  if (length(batter_id) == 0 | length(pitcher_id) == 0) {
    stop("Could not find player ID(s) for batter or pitcher.")
  }
  
  # Filter to relevant pitches
  df <- statcast_data %>%
    filter(batter == batter_id,
           pitch_name == !!pitch_type,
           pitcher == pitcher_id,
           !is.na(launch_angle),
           !is.na(launch_speed),
           !(description =="foul")
    )
  
  if (nrow(df) == 0) {
    #warning("No matching batted balls found for this batter/pitcher/pitch_type combination.")
    return(NULL)
  }
  
  # Define 5-unit bins for launch angle and launch speed
  df_binned <- df %>%
    mutate(
      la_bin = cut(launch_angle, breaks = seq(-90, 90, by = width), include.lowest = TRUE, right = FALSE),
      ev_bin = cut(launch_speed, breaks = seq(0, 120, by = width), include.lowest = TRUE, right = FALSE)
    ) %>%
    dplyr::count(la_bin, ev_bin) %>%
    mutate(freq = n / sum(n))
  
  # Fill in any empty bins for plotting completeness
  all_bins <- expand.grid(
    la_bin = levels(cut(seq(-90, 90, by = 5), breaks = seq(-90, 90, by = width), include.lowest = TRUE, right = FALSE)),
    ev_bin = levels(cut(seq(0, 120, by = 5), breaks = seq(0, 120, by = width), include.lowest = TRUE, right = FALSE))
  )
  
  df_complete <- all_bins %>%
    left_join(df_binned, by = c("la_bin", "ev_bin")) %>%
    mutate(freq = replace_na(freq, 0))
  
  return(df_complete)
}
