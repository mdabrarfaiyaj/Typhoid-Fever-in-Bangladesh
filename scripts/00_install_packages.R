# scripts/00_install_packages.R
# ============================================================
# Run this ONCE to install all required packages
# CHRF Portfolio — S. Typhi AMR Bangladesh
# ============================================================

cat("Installing required packages...\n")
cat("This may take 5–10 minutes the first time.\n\n")

pkgs <- c(
  # Core data wrangling
  "tidyverse",
  "readxl",
  "janitor",
  "here",
  # Visualisation
  "patchwork",
  "ggtext",
  # Reporting
  "kableExtra",
  # Shiny dashboard
  "shiny",
  "bslib",
  "plotly",
  "DT",
  # Reproducibility
  "renv"
)

# Install any that are missing
to_install <- pkgs[!pkgs %in% installed.packages()[,"Package"]]
if (length(to_install) > 0) {
  cat("Installing:", paste(to_install, collapse=", "), "\n")
  install.packages(to_install, repos = "https://cran.rstudio.com/")
} else {
  cat("All packages already installed!\n")
}

# Check Quarto is available
if (nzchar(Sys.which("quarto"))) {
  cat("Quarto found:", system("quarto --version", intern=TRUE), "\n")
} else {
  cat("  Quarto not found. Download from: https://quarto.org/docs/get-started/\n")
}

cat("\n Package setup complete. You can now run scripts 01 → 04.\n")
