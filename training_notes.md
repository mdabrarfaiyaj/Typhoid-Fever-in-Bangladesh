# Training Notes: Reproducing AMR Surveillance Analysis in R
*Written by: Md Abrar Faiyaj| CHRF Portfolio, June 2026*

---

## The Paper I am Reproducing

Tanmoy AM, Hooda Y, Sajib MSI et al. (2024).
"Trends in AMR in *S.* Typhi, Bangladesh: A 24-year observational study (1999–2022)"
*PLOS Neglected Tropical Diseases* 18(10): e0012558
doi: [10.1371/journal.pntd.0012558](https://doi.org/10.1371/journal.pntd.0012558)

**Why this paper:** It is a CHRF paper — published by the scientists at the
institution this portfolio is aimed at. The supplementary data is publicly
available, the biological question is directly actionable for Bangladesh
public health policy, and its findings contributed to the evidence base for
the nationwide TCV campaign launched 12 October 2025.

---

## Two Data Layers

| Layer | Source | What it contains |
|-------|--------|-----------------|
| **Phenotypic** | Tanmoy et al. 2024 Supp. S1 | Raw isolate data: each row = one patient, columns = R/S/I for each antibiotic |
| **Genomic** | TyphiNET Database (typhinet.org) | WGS isolates: genotype, resistance mutations (gyrA, parC, acrB), CipNS/CipR/XDR |

These two layers answer different questions:
- Phenotypic: **what** resistance looks like (% resistant in culture each year)
- Genomic: **why** resistance exists (the exact mutations encoding it)

---

## Core Concepts

| Term | Meaning |
|------|---------|
| MDR | Resistant to ampicillin + chloramphenicol + cotrimoxazole (all three simultaneously) |
| Non-susceptible (NS) | Resistant OR intermediate MIC — for ciprofloxacin, both R and I are clinical failures |
| R / S / I | Resistant / Susceptible / Intermediate — standard phenotypic AST categories |
| CipNS | Ciprofloxacin non-susceptible: R + I combined |
| CipR | Ciprofloxacin fully resistant (R only) — higher level, requires additional mutations |
| XDR | Extensively drug-resistant: MDR + resistant to ciprofloxacin + ceftriaxone |
| WGS | Whole Genome Sequencing — reads the entire bacterial genome |
| Genotype | Genetic lineage of the isolate (e.g. 4.3.1 = H58, the dominant global AMR lineage) |
| gyrA S83F | A point mutation in the gyrA gene at position 83 (serine → phenylalanine) — the primary driver of ciprofloxacin non-susceptibility in *S.* Typhi |
| DDD | Defined Daily Dose — WHO standard measure of antibiotic consumption (not in this dataset) |
| CLSI | Clinical and Laboratory Standards Institute — sets MIC breakpoints defining R/I/S |
| TCV | Typhoid Conjugate Vaccine — the vaccine whose introduction this data argues for |
| MIC | Minimum Inhibitory Concentration — lowest antibiotic dose preventing visible growth |

---

## Biological Question

**Does declining MDR mask rising resistance to newer antibiotics?**

**Answer from the data: Yes.**

The treatment ladder for typhoid in Bangladesh today:

| Drug | Route | Status |
|------|-------|--------|
| ~~Ampicillin, chloramphenicol, cotrimoxazole~~ | Oral | Largely abandoned — MDR |
| Ciprofloxacin | Oral | >90% non-susceptible throughout 1999–2022 |
| Azithromycin | Oral | Low resistance but rising; genomic escalation visible |
| Ceftriaxone | IV (hospital) | Still effective; no XDR in Bangladesh yet |

As oral options erode, prevention via TCV becomes the only sustainable strategy.

---

## Why Declining MDR Is Misleading

MDR fell because Bangladesh stopped prescribing cotrimoxazole as widely.
Bacteria stopped accumulating resistance to a drug that wasn't being used.
This is NOT biological improvement — the bacteria did not lose resistance genes,
they simply weren't under selection pressure from those drugs anymore.

Meanwhile, the drugs that *replaced* cotrimoxazole — ciprofloxacin, azithromycin —
are now under heavy selection pressure. The same cycle is repeating.

---

## The gyrA S83F Finding (Genomic Layer)

- 78% of all Bangladesh WGS isolates carry the gyrA S83F mutation
- This single mutation causes ciprofloxacin non-susceptibility (CipNS)
- It has essentially swept through the entire Bangladesh *S.* Typhi population
- This explains mechanistically why the phenotypic CipNS line sits near 100%

**Key escalation signal:** CipR (full resistance, typically requiring a second
mutation such as parC E84K) rose from 0.9% (2016) to 8.2% (2018). The bacteria
are accumulating additional mutations. The situation is not static.

**Bangladesh vs Pakistan:** Bangladesh = 0% XDR. Pakistan = 35.4% XDR.
Pakistan's XDR outbreak (2016–2019) arose from exactly the trajectory Bangladesh
is currently on. Bangladesh is at the inflection point.

---

## Statistical Methods Explained

### Linear regression for trend detection
```r
fit <- lm(pct_resistant ~ year, data = d)
```
Draws a straight line through the annual data points and asks: what is the slope?

- **Slope**: percentage points of resistance change per year
  - Negative slope = resistance falling
  - Positive slope = resistance rising
- **R²**: how well the straight line fits (0 = no fit, 1 = perfect fit)
- **p-value**: probability the slope is zero (i.e. no trend)
  - p < 0.05 = the trend is statistically real, not due to chance

### Period summary
Groups 24 individual years into five eras and calculates mean resistance per era.
Easier to describe in a policy report than 24 individual data points.

### Aggregating raw isolate data
The Tanmoy supplementary file contains **individual isolate data** (each row = one patient).
To get annual resistance rates, we calculate:

```r
pct_resistant = (number of isolates with "R") / (total isolates that year) × 100
```

For ciprofloxacin non-susceptibility specifically:
```r
pct_cip_ns = (isolates with "R" OR "I") / total × 100
```
Because "Intermediate" MIC for ciprofloxacin is a clinical failure — the drug
does not work even though it is not technically "Resistant."

---

## Key R Packages and What They Do

| Package | Purpose |
|---------|---------|
| tidyverse | Core toolkit: dplyr (data wrangling), ggplot2 (visualisation), tidyr, readr |
| readxl | Read Excel (.xlsx) files into R |
| janitor | `clean_names()` standardises messy column headers to snake_case |
| here | `here("data","raw","file.csv")` — portable file paths that work on any OS |
| patchwork | Combine multiple ggplot panels into one figure |
| ggtext | Italic/bold text in ggplot titles using markdown syntax |
| shiny | Build interactive web applications in R |
| bslib | Modern Bootstrap themes for Shiny dashboards |
| plotly | Convert ggplots to interactive charts (hover, zoom) |
| DT | Interactive, filterable data tables in Shiny/Quarto |
| kableExtra | Formatted, styled tables in Quarto reports |
| quarto | R interface to render .qmd files to HTML/PDF/Word |
| renv | Locks R package versions for reproducibility |

---

## What Is Quarto?

Quarto is a tool that combines R code, figures, and written text into a
single reproducible document. You write one `.qmd` file — Quarto runs
all the code, captures all outputs, and produces a self-contained HTML file.

**Why it matters for science:**
- When data changes, the entire document updates automatically
- Numbers in the text come directly from the analysis — no copy-paste errors
- Anyone can clone the repo and produce the identical document
- The `embed-resources: true` setting makes the HTML fully self-contained —
  no internet needed to view it, no R needed to read it

**How to render:**
```r
quarto::quarto_render("analysis/report.qmd")
```

**How to publish to GitHub Pages:**
```r
file.copy("analysis/report.html", "docs/index.html", overwrite = TRUE)
# Then git add, commit, push — GitHub Pages serves docs/index.html automatically
```

---

## What Is Posit Cloud?

Posit Cloud (cloud.posit.co) is RStudio running in your browser — no local
installation needed. You upload your project folder (including `.Rproj` file),
and your full analysis environment runs on Posit's servers.

**For this project:**
1. Upload the full project folder to Posit Cloud
2. Run `renv::restore()` to install all packages from `renv.lock`
3. Run scripts 01–04 to generate the processed data
4. Run `shiny::runApp("shiny/app.R")` to launch the dashboard
5. Use Posit Cloud's "Publish" button to get a shareable URL

**Why `here()` works on Posit Cloud:**
The `here` package looks for the `.Rproj` file to set the project root.
As long as the `.Rproj` file is in the top-level folder, all paths like
`here("data","processed","bangladesh_amr.rds")` resolve correctly regardless
of where Posit Cloud sets the working directory.

---

## How to Reproduce Everything

```
1. Clone: git clone https://github.com/mdabrarfaiyaj/Typoid-Fever-in-Bangladesh

2. Open project in RStudio (or Posit Cloud)

3. Install packages:
   source("scripts/00_install_packages.R")

4. Download data to data/raw/:
   - tanmoy2024_suppS1.xlsx  (from doi.org/10.1371/journal.pntd.0012558)
   - TyphiNET-database.csv   (from https://www.typhi.net/)

5. Run scripts in order:
   source("scripts/01_data_prep.R")          # check column names, fix rename() if needed
   source("scripts/02_temporal_analysis.R")
   source("scripts/03_visualizations.R")
   source("scripts/04_global_context.R")

6. Render report:
   quarto::quarto_render("analysis/report.qmd")
   file.copy("analysis/report.html", "docs/index.html", overwrite = TRUE)

7. Launch dashboard:
   shiny::runApp("shiny/app.R")
```

---

## Why Reproducibility Matters for CHRF

CHRF produces surveillance data that informs national vaccine policy in Bangladesh.
If an analysis cannot be reproduced:
- Findings cannot be independently verified before influencing policy
- Results cannot be updated when new isolate data arrives next year
- Training workshops cannot walk trainees through identical steps

`renv` ensures identical package versions across machines and time.
`here` ensures identical file paths across operating systems.
`quarto` ensures the document and the analysis are permanently in sync.

---

## References

1. Tanmoy AM et al. (2024). PLOS NTDs 18(10): e0012558.
   https://doi.org/10.1371/journal.pntd.0012558

2. TyphiNET Database. Wellcome Sanger Institute.
   https://www.typhinet.org

3. Tanmoy AM et al. (2018). mBio 9(6): e02112-18.

4. Government of Bangladesh, UNICEF, Gavi, WHO (2025).
   Bangladesh launches nationwide TCV campaign — 50 million children.
   Launch date: 12 October 2025.
