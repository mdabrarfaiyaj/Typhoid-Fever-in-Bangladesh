# scripts/02_temporal_analysis.R
# ============================================================
# Temporal Analysis: Period summary + Linear trends
# CHRF Portfolio — S. Typhi AMR Bangladesh
# ============================================================

library(tidyverse)
library(here)

bangladesh <- readRDS(here("data", "processed", "bangladesh_amr.rds"))

cat("Loaded", nrow(bangladesh), "rows (years),", ncol(bangladesh), "columns\n")
cat("Years covered:", min(bangladesh$year), "–", max(bangladesh$year), "\n\n")

# ── 1. Period-level summary ──────────────────────────────────
period_summary <- bangladesh %>%
  group_by(period) %>%
  summarise(
    n_isolates   = sum(n_total, na.rm = TRUE),
    mean_mdr     = round(mean(pct_mdr, na.rm = TRUE), 1),
    mean_cip_ns  = round(mean(pct_cip_ns, na.rm = TRUE), 1),
    mean_cef     = round(mean(pct_cef, na.rm = TRUE), 1),
    mean_azi     = round(mean(pct_azi, na.rm = TRUE), 1),
    .groups = "drop"
  )

write_csv(period_summary, here("results", "period_summary.csv"))
cat("=== Period Summary ===\n")
print(period_summary)
cat("\n")

# ── 2. Linear trend regression per antibiotic ────────────────
ab_cols <- list(
  "MDR"              = "pct_mdr",
  "Ciprofloxacin NS" = "pct_cip_ns",
  "Ceftriaxone"      = "pct_cef",
  "Azithromycin"     = "pct_azi",
  "Ampicillin"       = "pct_amp",
  "Chloramphenicol"  = "pct_chl",
  "Cotrimoxazole"    = "pct_cot"
)

trend_results <- purrr::map_dfr(names(ab_cols), function(ab_name) {
  col <- ab_cols[[ab_name]]
  if (!col %in% names(bangladesh)) {
    cat(" Column not found:", col, "— skipping", ab_name, "\n")
    return(NULL)
  }
  d <- bangladesh %>% select(year, pct = all_of(col)) %>% filter(!is.na(pct))
  if (nrow(d) < 3) {
    cat(" Not enough data for", ab_name, "(n =", nrow(d), ") — skipping\n")
    return(NULL)
  }
  fit <- lm(pct ~ year, data = d)
  tibble(
    antibiotic         = ab_name,
    slope_pct_per_year = round(coef(fit)[["year"]], 2),
    r_squared          = round(summary(fit)$r.squared, 3),
    p_value            = round(summary(fit)$coefficients["year","Pr(>|t|)"], 4),
    direction          = ifelse(coef(fit)[["year"]] > 0, "Increasing ↑", "Decreasing ↓"),
    significant        = ifelse(summary(fit)$coefficients["year","Pr(>|t|)"] < 0.05, "Yes", "No")
  )
})

write_csv(trend_results, here("results", "trend_regression.csv"))
cat("=== Linear Trend Regression Results ===\n")
print(trend_results)
cat("\n")

cat("=== Temporal analysis complete. Results saved to results/ folder ===\n")