Major League Baseball's Statcast system uses high-speed cameras and Doppler radon to track every pitch and batted ball. It provides detailed measurements such as pitch velocity, spin rate, movement, and location data, as well as batted-ball metrics like exit velocity, launch angle, distance, and play outcomes. This rich, pitch-by-pitch dataset enables deep analysis of player tendencies, pitch characteristics, and offensive performance.

This project has two main goals:

**1. Understanding Pitch and Batter Performance Structures**
I explore the structure of pitch characteristics and batter performance being dimensionality-reduction and clustering techniques. t-SNE and PCA are used to visualize similarities among pitches and identify major axes of variation. Gaussian mixture models then cluster pitches based on their physical properties, allowing comarison between data-driven clusters and Statcast pitch labels. A parallel workflow examines batters' performance profiles across pitch types. The project includes interactive visualizations linking pitches and performance metrics.

**2. Predicting Batter-Pitcher Outcomes Under Data Sparsity**
Individual batter-pitcher matchups are often too sparse to support reliable prediction. To address this, I adapt ideas from the Synethetic Estimated Average Matchup (SEAM) framework to augment sparse matchups with data from similar pitchers and similar batters. By borrowing observations from players with comparable pitch characteristics or batting performance profiles, the application estimates the expected distribution of exit velocity and launch angle for a given matchup, along with derived metrics such as expected batting average on balls in play and expected total bases.

![](shiny_app_example.png)