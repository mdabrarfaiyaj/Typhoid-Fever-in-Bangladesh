# scripts/03_visualizations.R
# ============================================================
# Visualizations: Publication-quality figures
# CHRF Portfolio — S. Typhi AMR Bangladesh
# ============================================================

library(tidyverse)
library(here)
library(patchwork)
library(ggtext)

bangladesh <- readRDS(here("data", "processed", "bangladesh_amr.rds"))

# ── Shared palette & theme ───────────────────────────────────
palette <- c(
  "MDR"              = "#2c7bb6",
  "Ciprofloxacin NS" = "#d7191c",
  "Ceftriaxone"      = "#f4a442",
  "Azithromycin"     = "#7b2d8b",
  "Ampicillin"       = "#1a9641",
  "Chloramphenicol"  = "#74add1",
  "Cotrimoxazole"    = "#abd9e9"
)

theme_chrf <- theme_minimal(base_size = 12) +
  theme(
    plot.title    = element_text(face = "bold", size = 13, color = "#1a2f5a"),
    plot.subtitle = element_text(color = "#555", size = 10.5),
    plot.caption  = element_text(color = "#888", size = 8.5, hjust = 0),
    panel.grid.minor  = element_blank(),
    legend.position   = "bottom",
    legend.title      = element_blank()
  )

# ── Figure 1: Main AMR Trends ────────────────────────────────
cat("Building Figure 1...\n")

fig1_data <- bangladesh %>%
  select(year, pct_mdr, pct_cip_ns, pct_cef, pct_azi) %>%
  pivot_longer(-year, names_to = "metric", values_to = "pct") %>%
  mutate(metric = recode(metric,
                         "pct_mdr"    = "MDR",
                         "pct_cip_ns" = "Ciprofloxacin NS",
                         "pct_cef"    = "Ceftriaxone",
                         "pct_azi"    = "Azithromycin"
  )) %>%
  filter(!is.na(pct))

fig1 <- ggplot(fig1_data, aes(x = year, y = pct, color = metric, group = metric)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2) +
  scale_color_manual(values = palette) +
  scale_x_continuous(breaks = seq(2000, 2022, 4)) +
  scale_y_continuous(limits = c(0, 107), labels = function(x) paste0(x, "%")) +
  labs(
    title    = "AMR Trends in *S.* Typhi, Bangladesh 1999–2022",
    subtitle = "MDR declines while ciprofloxacin non-susceptibility remains entrenched",
    x = NULL, y = "% of isolates",
    caption  = "Source: Tanmoy et al. 2024, PLOS Neglected Tropical Diseases"
  ) +
  theme_chrf +
  theme(plot.title = element_markdown())

ggsave(here("figures", "fig1_amr_trends.png"), fig1, width = 10, height = 5.5, dpi = 300)
cat("Figure 1 saved\n")

# ── Figure 2: Classical vs Modern Antibiotics ────────────────
cat("Building Figure 2...\n")

fig2 <- bangladesh %>%
  select(year, pct_amp, pct_chl, pct_cot, pct_cip_ns, pct_cef, pct_azi) %>%
  rename_with(~ recode(.,
                       "pct_amp"    = "Ampicillin",
                       "pct_chl"    = "Chloramphenicol",
                       "pct_cot"    = "Cotrimoxazole",
                       "pct_cip_ns" = "Ciprofloxacin NS",
                       "pct_cef"    = "Ceftriaxone",
                       "pct_azi"    = "Azithromycin"
  ), -year) %>%
  pivot_longer(-year, names_to = "antibiotic", values_to = "pct") %>%
  filter(!is.na(pct)) %>%
  mutate(class = case_when(
    antibiotic %in% c("Ampicillin","Chloramphenicol","Cotrimoxazole") ~ "First-line (classical)",
    TRUE ~ "Second/third-line"
  )) %>%
  ggplot(aes(x = year, y = pct, color = antibiotic)) +
  geom_line(linewidth = 1.1) +
  geom_point(size = 1.8) +
  facet_wrap(~class, scales = "free_y") +
  scale_color_manual(values = palette) +
  scale_x_continuous(breaks = seq(2000, 2022, 4)) +
  scale_y_continuous(labels = function(x) paste0(x,"%")) +
  labs(
    title    = "Diverging AMR Trajectories: Classical vs Modern Antibiotics",
    subtitle = "First-line resistance declining; newer drug resistance rising",
    x = NULL, y = "% of isolates",
    caption  = "Source: Tanmoy et al. 2024"
  ) +
  theme_chrf

ggsave(here("figures","fig2_drug_class_divergence.png"), fig2, width = 11, height = 5, dpi = 300)
cat("Figure 2 saved\n")

# ── Figure 3: Period Summary Bar Chart ───────────────────────
cat("Building Figure 3...\n")

fig3 <- bangladesh %>%
  group_by(period) %>%
  summarise(
    MDR                = mean(pct_mdr,    na.rm = TRUE),
    `Ciprofloxacin NS` = mean(pct_cip_ns, na.rm = TRUE),
    Ceftriaxone        = mean(pct_cef,    na.rm = TRUE),
    Azithromycin       = mean(pct_azi,    na.rm = TRUE),
    .groups = "drop"
  ) %>%
  filter(!is.na(period)) %>%
  pivot_longer(-period, names_to = "ab", values_to = "mean_pct") %>%
  filter(!is.na(mean_pct)) %>%
  ggplot(aes(x = period, y = mean_pct, fill = ab)) +
  geom_col(position = position_dodge(0.8), width = 0.7) +
  geom_text(aes(label = paste0(round(mean_pct,0),"%")),
            position = position_dodge(0.8), vjust = -0.4, size = 2.8) +
  scale_fill_manual(values = c(
    "MDR"              = "#2c7bb6",
    "Ciprofloxacin NS" = "#d7191c",
    "Ceftriaxone"      = "#f4a442",
    "Azithromycin"     = "#7b2d8b"
  )) +
  scale_y_continuous(limits = c(0,110), labels = function(x) paste0(x,"%")) +
  labs(
    title    = "AMR Prevalence by Surveillance Period",
    subtitle = "Mean resistance rate per period (1999–2022)",
    x = NULL, y = "Mean % resistant",
    caption  = "Source: Tanmoy et al. 2024"
  ) +
  theme_chrf +
  theme(axis.text.x = element_text(angle = 20, hjust = 1))

ggsave(here("figures","fig3_period_summary.png"), fig3, width = 10, height = 5, dpi = 300)
cat("Figure 3 saved\n")

cat("\n=== All figures saved to figures/ folder ===\n")