# Spatial and Temporal Modeling of Organized Crime-Related Offenses in Mexico

This repository contains the data preparation, exploratory analysis, model fitting, and comparison workflows for a thesis on municipal crime counts in Mexico from 2015 to 2025. The unit of analysis is the municipality-year. The project examines temporal persistence, spatial clustering, and candidate pathways of spatial diffusion using count models and Bayesian spatial models.

The outcome is a count of investigation files for a defined set of offenses studied in the thesis. These administrative records are a measure of reported and registered crime; they are not a direct measure of organized-crime membership or of all offenses that occurred.

### Contact & Support

For questions, collaborations, or suggestions:

**Franco Josué Patiño Morales, M.Sc.**  
Email: franco.jpm@gmail.com

### Citation

If you use this repository, cite the version or commit you used. Replace the placeholders below with the repository URL, publication year, and archived DOI, if available:

> Patiño Morales, F. J. (2026). *Modeling Spatial Diffusion and Infrastructure Resilience: A Bayesian Approach to Operational Risk* [Python] & [R]. GitHub. https://github.com/FrancoJPM1991/organized_crime_bayesian_prediction.git.

Related thesis or article: forthcoming. Do not cite this repository as a published article.

## Overview & Methodology

The study compares how temporal variation, persistent municipal differences, and spatial structure contribute to the distribution of recorded offenses. Municipality-level counts are analyzed with population as an exposure term where the model requires it. Spatial connectivity is initially defined through queen contiguity; additional connectivity matrices are planned for logistics, economic, sociodemographic, petroleum, and institutional links.

The analysis distinguishes **spatial association** from **spatial diffusion**. A significant Moran's I or an improved spatial model indicates that neighboring municipalities have related outcomes under the specified model. It does not, by itself, establish transmission or causality.

### Analytical components

1. **Descriptive analysis:** Annual totals, population-adjusted rates, zero counts, dispersion, extreme values, and concentration among municipalities.
2. **Exploratory spatial analysis:** Global Moran's I, global Getis-Ord G, local Moran (LISA), and local Getis-Ord statistics.
3. **Temporal analysis:** Annual trends, municipality-aligned rank correlations, and transitions between count states.
4. **Distributional diagnosis:** Poisson, negative binomial, zero-inflated, and hurdle specifications; diagnostics for overdispersion and zero counts.
5. **Spatial modeling:** Temporal RW1 effects, municipal IID effects, and BYM2 effects using a municipal adjacency graph.
6. **Comparison and validation:** AIC/BIC where appropriate, WAIC/DIC/CPO for comparable INLA fits, predictive checks, and planned temporal holdouts.

## Core Analytical Pipeline

1. **Data preparation:** Assemble municipal offense counts, population estimates, identifiers, and year labels. Check missing values and align municipal identifiers across years and spatial layers.
2. **Descriptive and exploratory spatial analysis:** Summarize count distributions and examine global and local geographic clustering.
3. **Temporal diagnosis:** Describe annual trajectories and municipality-level persistence. Correlations must match observations by municipality identifier before calculation.
4. **Distributional diagnosis:** Evaluate overdispersion and the predicted number of zeros using each model's own probability mass function on a common analytic sample.
5. **Contiguity graph:** Build and check queen-neighbor relationships, including disconnected municipalities and graph-to-data ordering.
6. **Baseline and spatial fits:** Compare temporal-only, temporal plus municipal IID, and temporal plus BYM2 specifications.
7. **Predictive validation:** Reserve later years for testing, assess count and zero predictions, and inspect calibration and residual spatial structure.
8. **Diffusion hypotheses (in development):** Construct and compare alternative connectivity matrices without treating improved fit alone as causal evidence.

The current `INLA` model code uses `zeroinflatednbinomial0`, a linear year term, and a RW1 year effect. Its probability model and fixed zero-component hyperparameter must be checked before describing it as equivalent to a frequentist hurdle negative binomial model. A frequentist hurdle baseline was fitted separately.

## Current Status

Completed analyses include descriptive, spatial, temporal, and distributional diagnostics; queen contiguity; a frequentist hurdle fit; and three `INLA` specifications with temporal-only, municipal IID, and BYM2 effects. In the reported `INLA` comparison, BYM2 has the lowest WAIC, DIC, and mean negative log CPO of those three fits. This is an in-sample/model-based comparison and does not establish superiority over the frequentist hurdle model on a temporal holdout.

The temporal transition-state definitions need to cover the threshold values 2, 5, and 17, and the rank-correlation code needs explicit matching by municipality. Diffusion matrices, their model fits, and temporal out-of-sample validation remain in progress.

## Getting Started

### Prerequisites

- Python with Jupyter and the packages used by the notebooks.
- R with the packages required by the fitting scripts, including `INLA` for Bayesian spatial fits and `pscl` for the frequentist hurdle benchmark.
- Access to the source data and municipal spatial boundaries. Some inputs may need to be obtained separately from their original providers.

### Installation

Clone **https://github.com/FrancoJPM1991/organized_crime_bayesian_prediction.git** and use the dependency files provided in that repository, if present. The example commands below are templates; update the URL and file names to match the actual repository.

```bash
git clone https://github.com/FrancoJPM1991/organized_crime_bayesian_prediction.git
cd REPOSITORY_DIRECTORY
python -m venv .venv
source .venv/bin/activate  ps1
pip install -r requirements.txt   file
```

Install R packages according to the repository's R dependency instructions. `INLA` has its own installation source; consult the project's installation instructions for the version used in a reproducible run.

### Key libraries used

- **Python:** pandas, NumPy, SciPy, statsmodels, matplotlib, and spatial-analysis packages used in the relevant scripts.
- **R:** `INLA` for latent Gaussian spatial models; `pscl` for the frequentist hurdle model.

### Suggested execution order

Run the files that exist in the checked-out repository in dependency order:

1. Prepare and validate municipal crime counts, population, and identifiers.
2. Run descriptive and exploratory spatial analyses.
3. Run `temporal_analysis.ipynb` and review municipality alignment and transition-state boundaries.
4. Run `distributive_diagnosis.ipynb` (or the filename present in the repository) on the same valid analytic sample for every model.
5. Build and validate the queen-contiguity graph.
6. Fit the frequentist benchmark and INLA temporal, IID, and BYM2 models.
7. Generate comparison tables, posterior summaries, maps, and predictive diagnostics.
8. When available, build alternative connectivity matrices and run temporal holdout comparisons.


## Repository Structure

```text
organized_crime_bayesian_prediction.git/
├── .RDataTmp1
├── .Rhistory
├── .gitignore
├── LICENSE
├── README.md
├── data/
│   ├── interim/
│   │   ├── contiguity_matrix.csv
│   │   ├── crime_count_2015-2025.csv
│   │   ├── crime_with_population.csv
│   │   └── population_2015_2025B.csv
│   ├── processed/
│   │   └── model_comparisson/
│   │       └── truncnb/
│   │           └── mun_index.csv
│   └── raw/
│       ├── economic/
│       │   ├── economic_output_xlsx/
│       │   │   └── SAIC_Exporta_2026617_233048143.csv
│       │   └── economic_units_locations_shp/
│       │       ├── denue_inegi_31-33_.fix
│       │       ├── denue_inegi_31-33_.prj
│       │       ├── denue_inegi_31-33_.qix
│       │       ├── denue_inegi_31-33_.shp
│       │       └── denue_inegi_31-33_.shx
│       └── geographic/
│           └── municipalities/
│               ├── 00mun.cpg
│               ├── 00mun.dbf
│               ├── 00mun.prj
│               └── 00mun.shx
├── notebooks/
│   ├── 00_difussion_matrices/
│   │   └── contiguity_matrix/
│   │       ├── .ipynb_checkpoints/
│   │       │   └── contiguity_matrix-checkpoint.ipynb
│   │       └── contiguity_matrix.ipynb
│   ├── 01_data_preprocessing/
│   │   ├── 01a_crime_per_municipality/
│   │   │   ├── .ipynb_checkpoints/
│   │   │   │   └── crime_data_preprocessing-checkpoint.ipynb
│   │   │   └── crime_data_preprocessing.ipynb
│   │   ├── 01b_population_per_municipality/
│   │   │   ├── .ipynb_checkpoints/
│   │   │   │   └── population_regression-checkpoint.ipynb
│   │   │   └── population_regression.ipynb
│   │   └── 01c_contiguity_matrix/
│   │       └── contiguity_matrix.ipynb
│   ├── 02_raw_descriptive_analysis/
│   │   ├── .ipynb_checkpoints/
│   │   │   ├── descriptive_analysis-checkpoint.ipynb
│   │   │   └── descriptive_maps-checkpoint.ipynb
│   │   ├── descriptive_analysis.ipynb
│   │   └── descriptive_maps.ipynb
│   ├── 03_raw_esda/
│   │   ├── .ipynb_checkpoints/
│   │   │   ├── G_mapping-checkpoint.ipynb
│   │   │   ├── LISA-checkpoint.ipynb
│   │   │   ├── LISA_mapping-checkpoint.ipynb
│   │   │   ├── g_local-checkpoint.ipynb
│   │   │   ├── getisordg-checkpoint.ipynb
│   │   │   ├── map_merging-checkpoint.ipynb
│   │   │   └── moransi-checkpoint.ipynb
│   │   ├── G_mapping.ipynb
│   │   ├── LISA.ipynb
│   │   ├── LISA_mapping.ipynb
│   │   ├── g_local.ipynb
│   │   ├── getisordg.ipynb
│   │   └── moransi.ipynb
│   ├── 04_distributional_diagnosis/
│   │   ├── .ipynb_checkpoints/
│   │   │   └── distributive_diagnosis-checkpoint.ipynb
│   │   └── distributive_diagnosis.ipynb
│   └── 05_temporal_analysis/
│       ├── .ipynb_checkpoints/
│       │   └── temporal_analysis-checkpoint.ipynb
│       └── temporal_analysis.ipynb
├── organized-crime-prediction.Rproj
├── results/
│   ├── raw_descriptive_analysis/
│   │   ├── 2015-2024_crime_counts_histograms.png
│   │   ├── 2015_crime_heatmap.png
│   │   ├── 2015_crimerate_hist.png
│   │   ├── 2016_crime_heatmap.png
│   │   ├── 2016_crimerate_hist.png
│   │   ├── 2017_crime_heatmap.png
│   │   ├── 2017_crimerate_hist.png
│   │   ├── 2018_crime_heatmap.png
│   │   ├── 2018_crimerate_hist.png
│   │   ├── 2019_crime_heatmap.png
│   │   ├── 2019_crimerate_hist.png
│   │   ├── 2020_crime_heatmap.png
│   │   ├── 2020_crimerate_hist.png
│   │   ├── 2021_crime_heatmap.png
│   │   ├── 2021_crimerate_hist.png
│   │   ├── 2022_crime_heatmap.png
│   │   ├── 2022_crimerate_hist.png
│   │   ├── 2023_crime_heatmap.png
│   │   ├── 2023_crimerate_hist.png
│   │   ├── 2024_crime_heatmap.png
│   │   ├── 2024_crimerate_hist.png
│   │   ├── 2025_crime_heatmap.png
│   │   ├── 2025_crimerate_hist.png
│   │   ├── NZ_boxplots.png
│   │   ├── concentration.csv
│   │   ├── concentration_top10.csv
│   │   ├── crime_count_evolution.png
│   │   ├── crime_heatmap_animation.gif
│   │   ├── crime_mean_evolution.png
│   │   ├── crimecount_hist_animation.gif
│   │   ├── data_descriptive_summary.csv
│   │   └── full_boxplots.png
│   ├── raw_esda_results/
│   │   ├── LISA_2015.png
│   │   ├── LISA_2016.png
│   │   ├── LISA_2017.png
│   │   ├── LISA_2018.png
│   │   ├── LISA_2019.png
│   │   ├── LISA_2020.png
│   │   ├── LISA_2021.png
│   │   ├── LISA_2022.png
│   │   ├── LISA_2023.png
│   │   ├── LISA_2024.png
│   │   ├── LISA_2025.png
│   │   ├── glocal_2015.png
│   │   ├── glocal_2016.png
│   │   ├── glocal_2017.png
│   │   ├── glocal_2018.png
│   │   ├── glocal_2019.png
│   │   ├── glocal_2020.png
│   │   ├── glocal_2021.png
│   │   ├── glocal_2022.png
│   │   ├── glocal_2023.png
│   │   ├── glocal_2024.png
│   │   ├── glocal_2025.png
│   │   ├── yearly_getisord_g.csv
│   │   ├── yearly_glocal_clusters.gif
│   │   ├── yearly_glocal_results.csv
│   │   ├── yearly_lisa_cluster_summary.csv
│   │   ├── yearly_lisa_clusters.gif
│   │   ├── yearly_lisa_results.csv
│   │   ├── yearly_localg_cluster_summary.csv
│   │   └── yearly_morans_I.csv
│   └── temporal_diagnosis_results/
│       ├── crime_count_plots.png
│       ├── transition_heatmap_pooled.png
│       └── transition_heatmaps.png
└── src/
    └── model_comparison/
        ├── models/
        │   ├── 01_model1_truncnb.R
        │   ├── 01_model1b_truncnb.R
        │   ├── 02_hurdle_frequentist_nb.R
        │   ├── 03_model2_bym2_truncnb.R
        │   └── 04_model3_spacetime_truncnb.R
        ├── pipeline/
        │   ├── 00_check_Type0_hurdle.R
        │   ├── 00_check_inla_families.R
        │   ├── 00_check_truncated_nb.R
        │   ├── 00_learn_inla_nb_rw1.R
        │   └── 01_moran_check_model2.R
        └── preprocessing/
            ├── 01_data_diagnose_na.R
            └── 01_prepare_data.R

```


