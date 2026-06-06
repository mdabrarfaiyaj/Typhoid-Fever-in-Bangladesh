# scripts/01_data_prep.R
# ============================================================
# Data Preparation:
#   1. Tanmoy et al. 2024 (phenotypic AMR, Bangladesh) - RAW ISOLATE DATA
#   2. TyphiNET database (genomic WGS, global)
# CHRF Portfolio — S. Typhi AMR Bangladesh
# ============================================================

library(tidyverse)
library(readxl)
library(janitor)
library(here)

# ── PART 1: Tanmoy et al. 2024 (Raw Isolate Data) ──────────────────────────────
cat("=== Loading Tanmoy et al. 2024 Supplementary S1 (Raw Isolates) ===\n")

tanmoy_raw <- read_excel(here("data", "raw", "tanmoy2024_suppS1.xlsx")) %>%
  clean_names()

cat("Column names found:\n")
print(names(tanmoy_raw))
cat("\nTotal isolates loaded:", nrow(tanmoy_raw), "\n\n")

# Summarize raw isolate data by Year
bangladesh <- tanmoy_raw %>%
  mutate(
    year = as.numeric(year),
    # Convert resistance calls to logical (TRUE = resistant)
    amp_r     = amoxicillin == "R",
    chl_r     = chloramphenicol == "R",
    cot_r     = cotrimoxazole == "R",
    cip_ns    = ciprofloxacin %in% c("R", "I"),     # Non-susceptible = R or I
    cef_r     = ceftriaxone == "R",
    azi_r     = azithromycin == "R",
    is_mdr    = mdr == "MDR"
  ) %>%
  group_by(year) %>%
  summarise(
    n_total     = n(),
    n_amp       = sum(amp_r, na.rm = TRUE),
    n_chl       = sum(chl_r, na.rm = TRUE),
    n_cot       = sum(cot_r, na.rm = TRUE),
    n_cip_ns    = sum(cip_ns, na.rm = TRUE),
    n_cef       = sum(cef_r, na.rm = TRUE),
    n_azi       = sum(azi_r, na.rm = TRUE),
    n_mdr       = sum(is_mdr, na.rm = TRUE),
    
    pct_amp     = mean(amp_r, na.rm = TRUE) * 100,
    pct_chl     = mean(chl_r, na.rm = TRUE) * 100,
    pct_cot     = mean(cot_r, na.rm = TRUE) * 100,
    pct_cip_ns  = mean(cip_ns, na.rm = TRUE) * 100,
    pct_cef     = mean(cef_r, na.rm = TRUE) * 100,
    pct_azi     = mean(azi_r, na.rm = TRUE) * 100,
    pct_mdr     = mean(is_mdr, na.rm = TRUE) * 100,
    
    .groups = "drop"
  ) %>%
  mutate(
    period = cut(year,
                 breaks = c(1998, 2004, 2009, 2014, 2018, 2022),
                 labels = c("1999–2004","2005–2009","2010–2014","2015–2018","2019–2022"),
                 include.lowest = TRUE)
  ) %>%
  arrange(year)

# Preview the result
cat("Summary by year:\n")
print(bangladesh %>% select(year, n_total, pct_mdr, pct_cip_ns, pct_cef, pct_azi))

# Save processed data
saveRDS(bangladesh, here("data", "processed", "bangladesh_amr.rds"))
write_csv(bangladesh, here("data", "processed", "bangladesh_amr.csv"))

cat("\n Tanmoy data summarized and saved:", nrow(bangladesh), "rows (years)\n\n")


# ── PART 2: TyphiNET Database (WGS genomic data) ────────────
cat("=== Loading TyphiNET Database ===\n")

typhinet_raw <- read_csv(
  here("data", "raw", "TyphiNET-database.csv"),
  locale   = locale(encoding = "latin1"),
  col_types = cols(Year = col_double(), .default = col_guess()),
  show_col_types = FALSE
)

cat("Total TyphiNET rows:", nrow(typhinet_raw), "\n")

# Keep only dashboard-quality isolates
typhinet <- typhinet_raw %>%
  filter(`Dashboard view` == "Include") %>%
  mutate(
    Year    = as.numeric(Year),
    is_mdr  = MDR == "MDR",
    is_xdr  = XDR == "XDR",
    is_H58  = str_starts(Genotype, "4.3.1")
  ) %>%
  rename(
    country  = Country,
    year     = Year,
    genotype = Genotype,
    cip_cat  = Cip,
    cip_ns   = CipNS,
    cip_r    = CipR,
    cef_r    = CefR
  )

cat("Include-only rows:", nrow(typhinet), "\n")

# Bangladesh genomic data
bd_genomic <- typhinet %>%
  filter(country == "Bangladesh", !is.na(year))

# South Asia genomic data
sa_genomic <- typhinet %>%
  filter(country %in% c("Bangladesh","Pakistan","India","Nepal"), !is.na(year))

saveRDS(typhinet,    here("data", "processed", "typhinet_global.rds"))
saveRDS(bd_genomic,  here("data", "processed", "bd_genomic.rds"))
saveRDS(sa_genomic,  here("data", "processed", "sa_genomic.rds"))

write_csv(bd_genomic, here("data", "processed", "bd_genomic.csv"))
write_csv(sa_genomic, here("data", "processed", "sa_genomic.csv"))

cat(" Bangladesh genomic isolates:", nrow(bd_genomic), "\n")
cat(" South Asia genomic isolates:", nrow(sa_genomic), "\n\n")

cat("=== ✅ Data prep complete. All datasets saved to data/processed/ ===\n")