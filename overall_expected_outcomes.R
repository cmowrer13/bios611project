all_pitches <- read_csv("raw_data/raw_data.csv")

build_xBABIP_xBsCON_grid <- function(statcast_data, width = 10){
  require(dplyr)
  
  hit_events <- c("single", "double", "triple", "home_run")
  
  base_values <- c(single = 1, double = 2, triple = 3, home_run = 4)
  
  grid_summary <- statcast_data %>%
    filter(!is.na(launch_angle),
           !is.na(launch_speed),
           events %in% c(hit_events, "double_play", "field_error", "field_out", "fielders_choice", "fielders_choice_out",
                         "force_out", "grounded_into_double_play")) %>%
    mutate(
      la_bin = cut(launch_angle, breaks = seq(-90, 90, by = width), include.lowest = TRUE, right = FALSE),
      ev_bin = cut(launch_speed, breaks = seq(0, 120, by = width), include.lowest = TRUE, right = FALSE),
      is_hit = events %in% hit_events,
      bases = recode(events, !!!base_values, .default = 0)
    ) %>%
    group_by(la_bin, ev_bin) %>%
    summarise(
      n = n(),
      hits = sum(is_hit, na.rm = TRUE),
      total_bases = sum(bases, na.rm = TRUE),
      xBABIP_bin = ifelse(n > 0, hits / n, NA_real_),
      xBsCON_bin = ifelse(n > 0, total_bases / n, NA_real_)
    ) %>%
    ungroup()
  
  return(grid_summary)
}

result <- build_xBABIP_xBsCON_grid(all_pitches)

smooth_sparse_cells <- function(grid, n_min = 10, la_width = 10, ev_width = 10) {
  require(dplyr)
  require(tidyr)
  require(stringr)
  
  # Extract numeric midpoints from "[10,20)" labels
  grid <- grid %>%
    mutate(
      la_mid = as.numeric(str_extract(la_bin, "(?<=\\[)-?\\d+(?=,)")) + la_width / 2,
      ev_mid = as.numeric(str_extract(ev_bin, "(?<=\\[)-?\\d+(?=,)")) + ev_width / 2
    )
  
  # Helper to find local average among neighbors within ±1 bin in both dimensions
  smooth_fun <- function(i, grid, width_la, width_ev) {
    la_i <- grid$la_mid[i]
    ev_i <- grid$ev_mid[i]
    
    neighborhood <- grid %>%
      filter(
        abs(la_mid - la_i) <= width_la + 1e-6,
        abs(ev_mid - ev_i) <= width_ev + 1e-6
      )
    
    tibble(
      xBABIP_smooth = weighted.mean(neighborhood$xBABIP_bin, neighborhood$n, na.rm = TRUE),
      xBsCON_smooth = weighted.mean(neighborhood$xBsCON_bin, neighborhood$n, na.rm = TRUE)
    )
  }
  
  # Iterate through grid
  smoothed_vals <- purrr::map_dfr(seq_len(nrow(grid)), smooth_fun, grid = grid,
                                  width_la = la_width, width_ev = ev_width)
  
  grid %>%
    bind_cols(smoothed_vals) %>%
    mutate(
      xBABIP_final = ifelse(n >= n_min, xBABIP_bin, xBABIP_smooth),
      xBsCON_final = ifelse(n >= n_min, xBsCON_bin, xBsCON_smooth)
    ) %>%
    select(-la_mid, -ev_mid)
}

result_smooth <- smooth_sparse_cells(result) %>% 
  select(la_bin, ev_bin, n, hits, total_bases, xBABIP_final, xBsCON_final) %>% 
  filter(complete.cases(.))

write.csv(result_smooth, "derived_data/expected_outcomes.csv")
