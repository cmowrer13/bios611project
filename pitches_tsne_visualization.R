library(tidyverse)
library(FactoMineR)
library(factoextra)
library(Rtsne)
library(cluster)
library(mclust)
library(plotly)
library(htmlwidgets)

set.seed(15)

all_pitches <- read_csv("raw_data/raw_data.csv")

pitch_profiles <- all_pitches %>% 
  filter(!pitch_name %in% c("Eephus", "Forkball", "Knuckleball", "Other", "Pitch Out", "Screwball", "Slow Curve", "Unknown")) %>% 
  filter(!is.na(pitch_name)) %>% 
  group_by(pitcher, pitch_name) %>% 
  summarize(across(c(release_speed, release_spin_rate, spin_axis, pfx_x, pfx_z, plate_x, plate_z),
                   mean, na.rm = T),
            n = n()) %>% 
  ungroup()

feature_cols <- c("release_speed", "release_spin_rate", "spin_axis", "pfx_x", "pfx_z", "plate_x", "plate_z")

pitch_profiles_scaled <- pitch_profiles %>%
  mutate(across(all_of(feature_cols), ~scale(.) %>% as.vector())) %>% 
  mutate(pitch_id = row_number()) %>% 
  filter(complete.cases(.))

feature_matrix <- as.matrix(pitch_profiles_scaled[, feature_cols])

# PCA to explore structure
pca_pitches <- prcomp(feature_matrix, scale = FALSE)

fviz_eig(pca_pitches)

p_pca <- fviz_pca_biplot(
  pca_pitches,
  geom = "point",
  habillage = pitch_profiles_scaled$pitch_name,
  addEllipses = FALSE
)

ggsave("figures/pca_biplot_pitches.png", p_pca, width = 8, height = 6)


# t-SNE visualization
tsne_pitches <- Rtsne(
  feature_matrix,
  dims = 2,
  perplexity = 30,
  check_duplicates = FALSE
)

tsne_df <- pitch_profiles_scaled %>%
  bind_cols(as.data.frame(tsne_pitches$Y)) %>%
  rename(tsne1 = V1, tsne2 = V2)

p_tsne <- ggplot(tsne_df, aes(tsne1, tsne2, color = pitch_name)) +
  geom_point(alpha = 0.7) +
  theme_minimal() +
  labs(title = "t-SNE of MLB Pitch Profiles (2025 Season)",
       color = "Pitch Name")

ggsave("figures/tsne_by_pitch.png", p_tsne, width = 8, height = 6)


# Gaussian mixture model and visualization
gmm <- Mclust(feature_matrix)

pitch_clusters <- pitch_profiles_scaled %>%
  mutate(cluster = gmm$classification)

player_ids <- read_csv("raw_data/player_ids.csv")

tsne_df_interactive <- tsne_df %>% 
  merge(pitch_profiles, by = c("pitcher", "pitch_name")) %>% 
  merge(player_ids, by.x = "pitcher", by.y = "key_mlbam") %>% 
  mutate(
    cluster = factor(gmm$classification),
    tooltip = paste0(
      "Pitcher: ", player_name, "<br>",
      "Pitch: ", pitch_name, "<br>",
      "Velocity: ", round(release_speed.y, 1), " mph<br>",
      "Spin Rate: ", round(release_spin_rate.y), " rpm<br>",
      "Spin Axis: ", round(spin_axis.y, 1), "°<br>",
      "Vertical Movement: ", 12*round(pfx_x.y, 2), " in<br>",
      "Horizontal Movement: ", 12*round(pfx_z.y, 2), " in<br>",
      "Location X: ", round(plate_x.y, 2), "<br>",
      "Location Z: ", round(plate_z.y, 2), "<br>",
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

ggsave("figures/tsne_clusters_static_pitches.png", p, width = 8, height = 6)

saveWidget(
  widget = p_interactive,
  file = "figures/tsne_clusters_interactive_pitches.html",
  selfcontained = TRUE
)

#table(Cluster = pitch_clusters$cluster, Name = pitch_profiles_scaled$pitch_name)
