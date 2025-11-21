library(tidyverse)
library(Rtsne)
library(mclust)
library(plotly)
library(htmlwidgets)

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
  select(batter, pitch_name, mean_la, sd_la, mean_ev, sd_ev, chase_rate, whiff_rate, n_pitches) %>% 
  mutate(batter_id = row_number())

feature_cols <- c("mean_la", "sd_la", "mean_ev", "sd_ev", "chase_rate", "whiff_rate")

batter_profiles_scaled <- batter_profiles %>%
  mutate(across(all_of(feature_cols), ~scale(.) %>% as.vector())) %>% 
  mutate(batter_id = row_number())

feature_matrix <- as.matrix(batter_profiles_scaled[, feature_cols])

# PCA to explore structure
pca_batters <- prcomp(feature_matrix, scale = FALSE)

fviz_eig(pca_batters)

p_pca <- fviz_pca_biplot(
  pca_batters,
  geom = "point",
  habillage = batter_profiles_scaled$pitch_name,
  addEllipses = FALSE
)

ggsave("figures/pca_biplot_batters.png", p_pca)

# t-SNE visualization
tsne_batters <- Rtsne(
  feature_matrix,
  dims = 2,
  perplexity = 30,
  check_duplicates = FALSE
)

tsne_df <- batter_profiles_scaled %>%
  bind_cols(as.data.frame(tsne_batters$Y)) %>%
  rename(tsne1 = V1, tsne2 = V2)

p_tsne <- ggplot(tsne_df, aes(tsne1, tsne2, color = pitch_name)) +
  geom_point(alpha = 0.7) +
  theme_minimal() +
  labs(title = "t-SNE of Batter Profiles (2025 Season)",
       color = "Pitch Name")

ggsave("figures/tsne_batters.png", p_tsne)

# Gaussian mixture model and visualization
gmm <- Mclust(feature_matrix)

batter_clusters <- batter_profiles_scaled %>%
  mutate(cluster = gmm$classification)

player_ids <- read_csv("raw_data/player_ids.csv")

tsne_df_interactive <- tsne_df %>% 
  merge(batter_profiles, by = c("batter", "pitch_name")) %>% 
  merge(player_ids, by.x = "batter", by.y = "key_mlbam") %>% 
  mutate(
    cluster = factor(gmm$classification),
    tooltip = paste0(
      "Batter: ", player_name, "<br>",
      "Pitch: ", pitch_name, "<br>",
      "Launch Angle Mean: ", round(mean_la.y, 1), "°<br>",
      "Launch Angle SD: ", round(sd_la.y), "°<br>",
      "Exit Velocity Mean: ", round(mean_ev.y, 1), " mph<br>",
      "Exit Velocity SD: ", round(sd_ev.y, 2), " mph<br>",
      "Chase Rate: ", 100*round(chase_rate.y, 3), "%<br>",
      "Whiff Rate: ", 100*round(whiff_rate.y, 3), "%<br>",
      "Cluster: ", cluster
    )
  )

p <- ggplot(tsne_df_interactive, aes(
  tsne1, tsne2, 
  color = cluster,
  text = tooltip 
)) +
  geom_point(alpha = 0.7) +
  theme_minimal() +
  labs(title = "t-SNE with Clusters")

p_interactive <- ggplotly(p, tooltip = "text")

saveWidget(
  widget = p_interactive,
  file = "figures/tsne_clusters_interactive_batters.html",
  selfcontained = TRUE
)

#table(Cluster = batter_clusters$cluster, Name = batter_profiles_scaled$pitch_name)
