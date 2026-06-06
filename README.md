# Antimicrobial Resistance Trends in *Salmonella* Typhi, Bangladesh (1999–2022)

[![R](https://img.shields.io/badge/R-4.3+-276DC3?logo=r)](https://www.r-project.org/)
[![Quarto](https://img.shields.io/badge/Report-Quarto-blue)](YOUR_GITHUB_PAGES_URL)
[![Shiny](https://img.shields.io/badge/Dashboard-Posit%20Cloud-orange)](YOUR_POSIT_CLOUD_URL)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)

---

## Why This Work Exists

On **12 October 2025**, Bangladesh became the **8th country in the world** to
launch a nationwide Typhoid Conjugate Vaccine campaign — reaching **50 million
children**, projected to prevent **6,000 deaths per year**.

That campaign was built on evidence. Central to that evidence is a 24-year
retrospective AMR surveillance study published by CHRF scientists in 2024:
Tanmoy AM, Hooda Y, Sajib MSI, Saha S, and colleagues. Their data — 12,435
culture-confirmed *Salmonella* Typhi isolates from Dhaka hospitals (1999–2022)
— made the policy argument that oral typhoid treatment was becoming unsustainable,
and that prevention through vaccination was the only durable answer.

This repository is a full reproducible re-analysis of that study, extended with
whole-genome sequencing data from the TyphiNET global surveillance database.
Every figure, every regression, every table here asks the same question the
original authors asked — and arrives at the same conclusion that shaped national policy.

---

## The Biological Question

> *Does declining multi-drug resistance (MDR) in Bangladesh represent genuine
> clinical progress — or does it mask a growing resistance burden for the
> limited antibiotics that remain viable for typhoid treatment?*

The antibiotics that remain — ciprofloxacin (oral), ceftriaxone (IV), and
azithromycin (oral) — are the entire treatment ladder for typhoid in Bangladesh
today. If they fail, there is no next line.

---

## Data Sources

| Layer | Source | Scale |
|-------|--------|-------|
| **Phenotypic** | [Tanmoy AM et al. (2024). *PLOS NTDs* 18(10): e0012558](https://doi.org/10.1371/journal.pntd.0012558) — Supplementary Data S1: raw isolate-level R/S/I data, Dhaka, 1999–2022 | 12,435 isolates |
| **Genomic** | [TyphiNET Database](https://www.typhinet.org) — Dashboard-quality WGS isolates; genotype, gyrA/parC/acrB mutations, CipNS/CipR/XDR classification | 1,664 Bangladesh WGS isolates |

Both datasets are publicly available. No data is simulated or synthetic.

---

## Key Findings

### Figure 1 — The central paradox
MDR declined from 38% (1999) to 17% (2022). Yet ciprofloxacin non-susceptibility
sat above 90% for the **entire 24-year period** without meaningful movement.
The MDR decline is real — but it reflects reduced use of drugs that were
already failing. The drugs that replaced them are now under the same pressure.

### Figure 2 — Two diverging trajectories
First-line antibiotics (ampicillin, chloramphenicol, cotrimoxazole) show
declining resistance. Second and third-line antibiotics (ciprofloxacin,
ceftriaxone, azithromycin) show flat or rising resistance. The problem
has not been solved — it has been transferred forward.

### Figure 3 — AMR by surveillance era
Period-level summaries confirm the trajectory: MDR bars shrink across eras,
cipro non-susceptibility bars remain uniformly tall, azithromycin resistance
shows the steepest relative growth in 2019–2022.

### Figure 4 — South Asia: Bangladesh has 0% XDR. Pakistan has 35.4%.
TyphiNET genomic data. Pakistan's XDR outbreak (2016–2019) arose from exactly
the resistance accumulation trajectory Bangladesh is currently on.
Bangladesh is at the inflection point — not past it.

### Figure 5 — The molecular mechanism
gyrA S83F alone is present in **78% of all Bangladesh WGS isolates** — a single
mutation that has swept through the *S.* Typhi population and explains the
near-universal ciprofloxacin non-susceptibility in culture. Full CipR (requiring
a second mutation) is now rising from 0.9% (2016) to 8.2% (2018). The problem
is escalating inside the flat line.

---

## Methods

**Trend analysis:** Linear regression per antibiotic — slope (% change per year),
R², p-value (significance threshold p < 0.05).

**Period summary:** Mean resistance rate across five predefined surveillance
eras (1999–2004, 2005–2009, 2010–2014, 2015–2018, 2019–2022).

**Genomic validation:** TyphiNET "Include" filter applied. CipNS/CipR trends
by year. gyrA/parC/acrB mutation prevalence. South Asia XDR comparison.

All analysis in R ≥ 4.3 · tidyverse · reproducible via renv.

---

## Reproduce This Analysis

```r
# 1. Install packages (once only)
source("scripts/00_install_packages.R")

# 2. Place data files in data/raw/ — see Data Download below

# 3. Process data
source("scripts/01_data_prep.R")         # inspect column names, fix rename() if needed

# 4. Analyse
source("scripts/02_temporal_analysis.R")
source("scripts/03_visualizations.R")
source("scripts/04_global_context.R")

# 5. Render report
quarto::quarto_render("analysis/report.qmd")
file.copy("analysis/report.html", "docs/index.html", overwrite = TRUE)

# 6. Launch dashboard
shiny::runApp("shiny/app.R")
```

---

## Data Download

**Tanmoy et al. 2024 — Supplementary Data S1:**
Go to https://doi.org/10.1371/journal.pntd.0012558 → Supporting Information → S1 Data.
Save as `data/raw/tanmoy2024_suppS1.xlsx`.

**TyphiNET Database:**
Download from https://www.typhinet.org → Data Downloads.
Save as `data/raw/TyphiNET-database.csv`.

> After downloading the Tanmoy file, run `source("scripts/01_data_prep.R")` and
> check the printed column names. Edit the `rename()` block if they differ from
> what the script expects. The script prints guidance on first run.

---

## Repository Structure

```
styphi-amr-bangladesh/
├── data/
│   ├── raw/                      ← Downloaded files (not committed to git)
│   └── processed/                ← Generated .rds and .csv (not committed)
├── scripts/
│   ├── 00_install_packages.R
│   ├── 01_data_prep.R            ← Aggregates raw R/S/I isolates → annual rates
│   ├── 02_temporal_analysis.R    ← Trend regression + period summary
│   ├── 03_visualizations.R       ← Figures 1–3 (phenotypic)
│   └── 04_global_context.R       ← Figures 4–5 (TyphiNET genomic)
├── analysis/
│   └── report.qmd                ← Quarto reproducible report
├── shiny/
│   └── app.R                     ← Interactive dashboard
├── results/                      ← CSV outputs from analysis
├── figures/                      ← PNG figures (300 dpi)
├── docs/
│   └── index.html                ← GitHub Pages (rendered report)
├── training_notes.md
├── renv.lock                     ← Reproducible R environment
└── README.md
```

---

## Live Links

| Resource | Link |
|----------|------|
| 📊 Interactive Dashboard | [Posit Cloud](YOUR_POSIT_CLOUD_URL) |
| 📄 Full Quarto Report | [GitHub Pages](YOUR_GITHUB_PAGES_URL) |
| 🧬 Primary Data | [Tanmoy et al. 2024, PLOS NTDs](https://doi.org/10.1371/journal.pntd.0012558) |
| 🌍 Genomic Data | [TyphiNET Database](https://www.typhinet.org) |

---

## References

1. Tanmoy AM, Hooda Y, Sajib MSI et al. (2024). Trends in antimicrobial resistance
   amongst *Salmonella* Typhi in Bangladesh: A 24-year retrospective observational
   study (1999–2022). *PLOS Neglected Tropical Diseases* 18(10): e0012558.
   https://doi.org/10.1371/journal.pntd.0012558

2. TyphiNET Database. Wellcome Sanger Institute and global collaborators.
   Whole-genome sequencing surveillance of *Salmonella* Typhi.
   https://www.typhinet.org

3. Tanmoy AM et al. (2018). *Salmonella* Typhi in Bangladesh: Genomic Diversity
   and Antimicrobial Resistance. *mBio* 9(6): e02112-18.

4. Government of Bangladesh, UNICEF, Gavi, WHO (2025). Bangladesh launches
   nationwide Typhoid Conjugate Vaccine campaign to protect 50 million children.
   Campaign launch: 12 October 2025.

---

