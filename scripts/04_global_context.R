# scripts/04_global_context.R
# ============================================================
# Genomic Global Context using TyphiNET Database
# ============================================================

library(tidyverse)
library(patchwork)
library(here)

sa_genomic <- readRDS(here("data","processed","sa_genomic.rds"))
bd_genomic <- readRDS(here("data","processed","bd_genomic.rds"))

cat("South Asia genomic isolates:", nrow(sa_genomic), "\n")
cat("Bangladesh genomic isolates:", nrow(bd_genomic), "\n\n")

theme_chrf <- theme_minimal(base_size = 12) +
  theme(
    plot.title    = element_text(face="bold", size=13, color="#1a2f5a"),
    plot.subtitle = element_text(color="#555", size=10.5),
    plot.caption  = element_text(color="#888", size=8.5, hjust=0),
    panel.grid.minor  = element_blank(),
    legend.position   = "bottom",
    legend.title      = element_blank()
  )

country_pal <- c(
  "Bangladesh" = "#d7191c",
  "Pakistan"   = "#2c7bb6",
  "India"      = "#1a9641",
  "Nepal"      = "#f4a442"
)

# ── Figure 4: South Asia AMR comparison ─────────────────────
cat("Building Figure 4...\n")

sa_summary <- sa_genomic %>%
  group_by(country) %>%
  summarise(
    n          = n(),
    pct_cipNS  = round(mean(cip_ns,  na.rm=TRUE)*100, 1),
    pct_cipR   = round(mean(cip_r,   na.rm=TRUE)*100, 1),
    pct_cefR   = round(mean(cef_r,   na.rm=TRUE)*100, 1),
    pct_xdr    = round(mean(is_xdr,  na.rm=TRUE)*100, 1),
    pct_mdr    = round(mean(is_mdr,  na.rm=TRUE)*100, 1),
    .groups = "drop"
  ) %>%
  pivot_longer(cols = starts_with("pct_"),
               names_to = "metric", values_to = "pct") %>%
  mutate(metric = recode(metric,
                         "pct_cipNS" = "Cipro Non-Susceptible",
                         "pct_cipR"  = "Cipro Fully Resistant",
                         "pct_cefR"  = "Ceftriaxone Resistant",
                         "pct_xdr"   = "XDR",
                         "pct_mdr"   = "MDR"
  ))

fig4 <- ggplot(sa_summary,
               aes(x = metric, y = pct, fill = country)) +
  geom_col(position = position_dodge(0.8), width = 0.7) +
  geom_text(aes(label = paste0(pct,"%")),
            position = position_dodge(0.8), vjust = -0.4, size = 2.6) +
  scale_fill_manual(values = country_pal) +
  scale_y_continuous(labels = function(x) paste0(x,"%"),
                     expand  = expansion(mult = c(0, 0.15))) +
  labs(
    title    = "Figure 4: South Asia Genomic AMR Profile Comparison",
    subtitle = "Bangladesh has no XDR (0%) — Pakistan leads with high XDR",
    x = NULL, y = "% of WGS isolates",
    caption  = "Source: TyphiNET Database — Dashboard-quality isolates only"
  ) +
  theme_chrf +
  theme(axis.text.x = element_text(angle=25, hjust=1))

ggsave(here("figures","fig4_south_asia_genomic.png"), fig4,
       width=11, height=5.5, dpi=300)
cat("Figure 4 saved\n")

# ── Figure 5: Bangladesh CipR escalation + gyrA mutation ─────
cat("Building Figure 5...\n")

# 5A: CipNS vs CipR over time
cip_by_year <- bd_genomic %>%
  filter(!is.na(year)) %>%
  group_by(year) %>%
  summarise(
    n         = n(),
    pct_cipNS = mean(cip_ns, na.rm=TRUE)*100,
    pct_cipR  = mean(cip_r,  na.rm=TRUE)*100,
    .groups = "drop"
  ) %>%
  filter(n >= 5) %>%
  pivot_longer(cols = c(pct_cipNS, pct_cipR),
               names_to = "level", values_to = "pct") %>%
  mutate(level = recode(level,
                        "pct_cipNS" = "CipNS (any non-susceptibility)",
                        "pct_cipR"  = "CipR (full resistance)"
  ))

p5a <- ggplot(cip_by_year, aes(x=year, y=pct, color=level, group=level)) +
  geom_line(linewidth=1.2) +
  geom_point(size=2.2) +
  scale_color_manual(values=c(
    "CipNS (any non-susceptibility)" = "#f4a442",
    "CipR (full resistance)"         = "#d7191c"
  )) +
  scale_x_continuous(breaks=seq(2005,2019,2)) +
  scale_y_continuous(limits=c(0,107), labels=function(x) paste0(x,"%")) +
  labs(
    title    = "Ciprofloxacin: Escalation Within a Flat Line",
    subtitle = "CipNS near-universal — but full CipR is rising",
    x = NULL, y = "% of WGS isolates"
  ) +
  theme_chrf

# 5B: gyrA mutation landscape
gyr_cols <- c("gyrA_S83F","gyrA_S83Y","gyrA_D87N","parC_E84K","acrB_R717Q")

gyr_data <- bd_genomic %>%
  filter(!is.na(year)) %>%
  select(year, all_of(gyr_cols)) %>%
  pivot_longer(-year, names_to="mutation", values_to="present") %>%
  mutate(present = as.numeric(present)) %>%
  group_by(mutation) %>%
  summarise(
    n_total   = n(),
    n_present = sum(present, na.rm=TRUE),
    pct       = round(n_present/n_total*100, 1),
    .groups   = "drop"
  ) %>%
  mutate(
    mutation = fct_reorder(mutation, pct),
    role = case_when(
      str_starts(mutation,"gyrA") ~ "GyrA (primary CipNS driver)",
      str_starts(mutation,"parC") ~ "ParC (secondary)",
      str_starts(mutation,"acrB") ~ "AcrB efflux pump"
    )
  )

p5b <- ggplot(gyr_data, aes(x=mutation, y=pct, fill=role)) +
  geom_col(width=0.7) +
  geom_text(aes(label=paste0(pct,"%")), hjust=-0.2, size=3.5) +
  scale_fill_manual(values=c(
    "GyrA (primary CipNS driver)" = "#d7191c",
    "ParC (secondary)"            = "#f4a442",
    "AcrB efflux pump"            = "#7b2d8b"
  )) +
  scale_y_continuous(limits=c(0,100), labels=function(x) paste0(x,"%")) +
  coord_flip() +
  labs(
    title    = "Molecular Basis of Ciprofloxacin Resistance",
    subtitle = "gyrA_S83F is the dominant mutation in Bangladesh",
    x = NULL, y = "% of Bangladesh WGS isolates"
  ) +
  theme_chrf +
  theme(legend.position = "right")

fig5 <- (p5a / p5b) +
  plot_annotation(
    caption = "Source: TyphiNET Database — Bangladesh WGS isolates"
  ) & theme_chrf

ggsave(here("figures","fig5_genomic_mechanism.png"), fig5,
       width=11, height=9, dpi=300)
cat("Figure 5 saved\n")

# ── Summary table ──────────────────────────────────────────
cat("\n=== Bangladesh Genomic Summary (TyphiNET) ===\n")
bd_summary <- bd_genomic %>%
  summarise(
    total_wgs      = n(),
    year_range     = paste(min(year,na.rm=T), "–", max(year,na.rm=T)),
    pct_cipNS      = paste0(round(mean(cip_ns,na.rm=T)*100,1),"%"),
    pct_cipR       = paste0(round(mean(cip_r, na.rm=T)*100,1),"%"),
    pct_xdr        = paste0(round(mean(is_xdr,na.rm=T)*100,1),"%"),
    pct_gyrA_S83F  = paste0(round(mean(gyrA_S83F,na.rm=T)*100,1),"%"),
    pct_H58        = paste0(round(mean(is_H58, na.rm=T)*100,1),"%")
  )
print(t(bd_summary))

write_csv(as.data.frame(t(bd_summary)),
          here("results","bd_genomic_summary.csv"))

cat("\n=== Global context complete. Figures 4 & 5 saved. ===\n")