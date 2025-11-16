.PHONY: all clean \
        contact_distribution_function \
        calculate_synthetic_distribution \
        plot_synthetic_laev \
        calculated_expected_outcomes_from_synthetic \
        shiny_app
        
all: report.html


## DIRECTORIES
raw_data/:
	mkdir -p raw_data/

derived_data/:
	mkdir -p derived_data/

figures/:
	mkdir -p figures/

## DATA PULLING
raw_data/raw_data.csv: pull_data.R | raw_data/
	Rscript pull_data.R

raw_data/player_ids.csv: pull_player_ids.R | raw_data/
	Rscript pull_player_ids.R
	
	
## DERIVED DATA
derived_data/similar_pitches.csv: find_similar_pitches.R raw_data/raw_data.csv raw_data/player_ids.csv | derived_data/
	Rscript find_similar_pitches.R

derived_data/similar_batters.csv: find_similar_batters.R raw_data/raw_data.csv raw_data/player_ids.csv | derived_data/
	Rscript find_similar_batters.R

derived_data/expected_outcomes.csv: overall_expected_outcomes.R raw_data/raw_data.csv | derived_data/
	Rscript overall_expected_outcomes.R
	
	
## FUNCTION-ONLY SCRIPTS
contact_distribution_function: contact_distribution_function.R
	@echo "Loaded contact_distribution_function.R"
	
calculate_synthetic_distribution: calculate_synthetic_distribution.R \
                                  derived_data/similar_pitches.csv \
                                  derived_data/similar_batters.csv \
                                  raw_data/player_ids.csv
	@echo "Loaded calculate_synthetic_distribution.R"
	
plot_synthetic_laev: plot_synthetic_laev.R
	@echo "Loaded plot_synthetic_laev.R"
	
calculated_expected_outcomes_from_synthetic: calculated_expected_outcomes_from_synthetic.R \
                                             derived_data/expected_outcomes.csv
	@echo "Loaded calculated_expected_outcomes_from_synthetic.R"
	
	
## FIGURES
figures/pca_biplot_pitches.png \
figures/tsne_by_pitch.png \
figures/tsne_clusters_interactive_pitches.html &: pitches_tsne_visualization.R raw_data/raw_data.csv raw_data/player_ids.csv | figures/
	Rscript pitches_tsne_visualization.R
	
figures/pca_biplot_batters.png \
figures/tsne_batters.png \
figures/tsne_clusters_interactive_batters.html &: batters_tsne_visualization.R raw_data/raw_data.csv raw_data/player_ids.csv | figures/
	Rscript batters_tsne_visualization.R
	
	
## SHINY APP
shiny_app: shiny_app.R \
           contact_distribution_function \
           calculate_synthetic_distribution \
           calculated_expected_outcomes_from_synthetic \
           plot_synthetic_laev \
           raw_data/raw_data.csv
	Rscript shiny_app.R
	
	
## REPORT
report.html: report.Rmd \
             figures/pca_biplot_pitches.png \
             figures/tsne_by_pitch.png \
             figures/tsne_clusters_interactive_pitches.html \
             figures/pca_biplot_batters.png \
             figures/tsne_batters.png \
             figures/tsne_clusters_interactive_batters.html
	Rscript -e "rmarkdown::render('report.Rmd', output_file='report.html', output_format='html_document')"


## CLEANING
clean:
	rm -rf raw_data/*.csv
	rm -rf derived_data/*.csv
	rm -rf figures/*
	rm -f report.html