expected <- read.csv("derived_data/expected_outcomes.csv")

get_expected_outcomes <- function(synthetic_distribution, expected_outcomes){
  
  syn_dist <- synthetic_distribution$smooth_distribution %>% 
    mutate(la_bin_num = case_when(
      la_bin == "[-90,-80)" ~ 1,
      la_bin == "[-80,-70)" ~ 2,
      la_bin == "[-70,-60)" ~ 3,
      la_bin == "[-60,-50)" ~ 4,
      la_bin == "[-50,-40)" ~ 5,
      la_bin == "[-40,-30)" ~ 6,
      la_bin == "[-30,-20)" ~ 7,
      la_bin == "[-20,-10)" ~ 8,
      la_bin == "[-10,0)" ~ 9,
      la_bin == "[0,10)" ~ 10,
      la_bin == "[10,20)" ~ 11,
      la_bin == "[20,30)" ~ 12,
      la_bin == "[30,40)" ~ 13,
      la_bin == "[40,50)" ~ 14,
      la_bin == "[50,60)" ~ 15,
      la_bin == "[60,70)" ~ 16,
      la_bin == "[70,80)" ~ 17,
      la_bin == "[80,90]" ~ 18),
      ev_bin_num = case_when(
        ev_bin == "[0,10)" ~ 1,
        ev_bin == "[10,20)" ~ 2,
        ev_bin == "[20,30)" ~ 3,
        ev_bin == "[30,40)" ~ 4,
        ev_bin == "[40,50)" ~ 5,
        ev_bin == "[50,60)" ~ 6,
        ev_bin == "[60,70)" ~ 7,
        ev_bin == "[70,80)" ~ 8,
        ev_bin == "[80,90)" ~ 9,
        ev_bin == "[90,100)" ~ 10,
        ev_bin == "[100,110)" ~ 11,
        ev_bin == "[110,120)" ~ 12,
      ))
  
  expected <- expected_outcomes %>% 
    mutate(la_bin_num = case_when(
      la_bin == "[-90,-80)" ~ 1,
      la_bin == "[-80,-70)" ~ 2,
      la_bin == "[-70,-60)" ~ 3,
      la_bin == "[-60,-50)" ~ 4,
      la_bin == "[-50,-40)" ~ 5,
      la_bin == "[-40,-30)" ~ 6,
      la_bin == "[-30,-20)" ~ 7,
      la_bin == "[-20,-10)" ~ 8,
      la_bin == "[-10,0)" ~ 9,
      la_bin == "[0,10)" ~ 10,
      la_bin == "[10,20)" ~ 11,
      la_bin == "[20,30)" ~ 12,
      la_bin == "[30,40)" ~ 13,
      la_bin == "[40,50)" ~ 14,
      la_bin == "[50,60)" ~ 15,
      la_bin == "[60,70)" ~ 16,
      la_bin == "[70,80)" ~ 17,
      la_bin == "[80,90]" ~ 18),
      ev_bin_num = case_when(
        ev_bin == "[0,10)" ~ 1,
        ev_bin == "[10,20)" ~ 2,
        ev_bin == "[20,30)" ~ 3,
        ev_bin == "[30,40)" ~ 4,
        ev_bin == "[40,50)" ~ 5,
        ev_bin == "[50,60)" ~ 6,
        ev_bin == "[60,70)" ~ 7,
        ev_bin == "[70,80)" ~ 8,
        ev_bin == "[80,90)" ~ 9,
        ev_bin == "[90,100)" ~ 10,
        ev_bin == "[100,110)" ~ 11,
        ev_bin == "[110,120]" ~ 12,
      ))
  
  syn_dist %>%
    left_join(expected, by = c("la_bin_num", "ev_bin_num")) %>%
    filter(!is.na(xBABIP_final)) %>% 
    summarise(
      xBABIP = sum(freq * xBABIP_final, na.rm = TRUE),
      xBsCON = sum(freq * xBsCON_final, na.rm = TRUE)
    )
}
