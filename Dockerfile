# Start from rocker/verse (includes R, tidyverse, knitr, etc.)
FROM rocker/verse:latest

# Ensure root
USER root

# Install TeX Live, Pandoc, and extra LaTeX packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    texlive-latex-base \
    texlive-latex-recommended \
    texlive-latex-extra \
    texlive-fonts-recommended \
    texlive-xetex \
    texlive-luatex \
    lmodern \
    pandoc \
    && rm -rf /var/lib/apt/lists/*

# Enable man pages in Ubuntu (non-interactive)
RUN apt-get update && apt-get install -y --no-install-recommends \
    man-db manpages manpages-dev less \
    && yes | unminimize \
    && rm -rf /var/lib/apt/lists/*

# Install/upgrade R packages for rendering
RUN Rscript -e "install.packages(c('rmarkdown', 'RANN', 'imager', 'shinycssloaders', 'FactoMineR', 'factoextra', 'Rtsne', 'cluster', 'mclust', 'plotly', 'htmlwidgets', repos='https://cloud.r-project.org')"
RUN Rscript -e "remotes::install_github('BillPetti/baseballr')"

# Default workdir
WORKDIR /home/rstudio/work