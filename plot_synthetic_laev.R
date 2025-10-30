plot_synthetic_laev <- function(synthetic_distribution){
  synthetic_distribution$smooth_distribution %>% 
    ggplot(aes(y = la_bin, x = ev_bin, fill = freq)) +
    geom_tile() +
    scale_fill_viridis_c() +
    coord_fixed() +
    labs(title = "Synthetic LA/EV Distribution",
         x = "Exit Velocity (mph)",
         y = "Launch Angle (degrees)",
         fill = "Frequency") +
    theme(axis.text.x = element_text(angle = -45, hjust = 0))
}
