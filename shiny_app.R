library(shiny)
library(imager)
library(tidyverse)
library(shinycssloaders)

source("contact_distribution_function.R")
source("calculate_synthetic_distribution.R")
source("calculated_expected_outcomes_from_synthetic.R")
source("plot_synthetic_laev.R")

all_pitches <- read_csv("raw_data/raw_data.csv")  %>% 
  filter(!pitch_name %in% c("Eephus", "Forkball", "Knuckleball", "Other", "Pitch Out", "Screwball", "Slow Curve")) %>% 
  filter(!is.na(pitch_name))

batters <- sort(unique(similar_batters$batter_name))
pitchers <- sort(unique(similar_pitches$pitcher_name))
pitch_types <- sort(unique(similar_pitches$pitch_name))

ui <- fluidPage(
  titlePanel("Synthetic LA/EV Explorer"),
  
  sidebarLayout(
    sidebarPanel(
      selectizeInput(
        "batter", "Batter:", 
        choices = batters, multiple = FALSE, 
        options = list(placeholder = "Type batter name...")
      ),
      selectizeInput(
        "pitcher", "Pitcher:", 
        choices = pitchers, multiple = FALSE, 
        options = list(placeholder = "Type pitcher name...")
      ),
      selectizeInput(
        "pitch_type", "Pitch Type:", 
        choices = NULL, multiple = FALSE, 
        options = list(placeholder = "Select a pitcher first...")
      ),
      actionButton("go", "Generate Synthetic Distribution", class = "btn-primary"),
      hr(),
      h4("Weights"),
      verbatimTextOutput("weights"),
      hr(),
      h4("Most Similar Batters"),
      tableOutput("similar_batters"),
      h4("Most Similar Pitches"),
      tableOutput("similar_pitches")
    ),
    
    mainPanel(
      h3("Synthetic LA/EV Distribution"),
      withSpinner(plotOutput("laev_plot", height = "500px")),
      hr(),
      fluidRow(
        column(6, h4("Expected BABIP"), textOutput("xbabip")),
        column(6, h4("Expected Bases on Contact"), textOutput("xbscon"))
      )
    )
  )
)

server <- function(input, output, session) {
  
  # --- Dynamically update pitch type options based on selected pitcher ---
  observeEvent(input$pitcher, {
    req(input$pitcher)
    
    valid_pitches <- similar_pitches %>%
      filter(pitcher_name == input$pitcher) %>%
      distinct(pitch_name) %>%
      pull(pitch_name) %>%
      sort()
    
    updateSelectizeInput(session, "pitch_type", choices = valid_pitches, server = TRUE)
  })
  
  # --- Reactive computations ---
  results <- eventReactive(input$go, {
    req(input$batter, input$pitcher, input$pitch_type)
    
    syn <- get_synthetic_distribution(
      statcast_data = all_pitches,
      batter_name = input$batter,
      pitcher_name = input$pitcher,
      pitch_type = input$pitch_type,
      width = 10
    )
    
    outcomes <- get_expected_outcomes(syn, expected)
    
    list(
      syn = syn,
      outcomes = outcomes
    )
  })
  
  # --- Outputs ---
  output$laev_plot <- renderPlot({
    req(results())
    plot_synthetic_laev(results()$syn)
  })
  
  output$xbabip <- renderText({
    req(results())
    sprintf("%.3f", results()$outcomes$xBABIP)
  })
  
  output$xbscon <- renderText({
    req(results())
    sprintf("%.3f", results()$outcomes$xBsCON)
  })
  
  output$weights <- renderPrint({
    req(results())
    results()$syn$weights
  })
  
  output$similar_batters <- renderTable({
    req(results())
    head(results()$syn$top_similar_batters, 3) %>%
      rename(
        `Similar Batter Name` = neighbor_batter_name
      ) %>%
      select(`Similar Batter Name`)
  })
  
  output$similar_pitches <- renderTable({
    req(results())
    head(results()$syn$top_similar_pitches, 3) %>%
      rename(
        `Similar Pitcher Name` = neighbor_pitcher_name,
        `Similar Pitch Type` = neighbor_pitch_name
      ) %>%
      select(`Similar Pitcher Name`, `Similar Pitch Type`)
  })
}

shinyApp(ui, server)
