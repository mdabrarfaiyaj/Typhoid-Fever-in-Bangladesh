# shiny/app.R
# ============================================================
# Shiny Dashboard: Salmonella Typhi AMR Bangladesh
# Two data layers:
#   Phenotypic — Tanmoy et al. 2024 (12,435 isolates)
#   Genomic    — TyphiNET database  (1,664 WGS isolates)
#
# Posit Cloud deployment notes:
#   1. Upload the FULL project folder (including .Rproj file)
#   2. Open as a Project in Posit Cloud — do not open as a plain folder
#   3. Run renv::restore() once to install all packages
#   4. Run scripts 01–04 to generate data/processed/*.rds files
#   5. shiny::runApp("shiny/app.R") from the project root
#
# Required packages (all handled by renv.lock):
#   shiny, bslib, tidyverse, plotly, DT, here
# ============================================================

library(shiny)
library(bslib)
library(tidyverse)
library(plotly)
library(DT)
library(here)

# ── Direct loading for shinyapps.io (more reliable) ───────────
bangladesh  <- readRDS("data/processed/bangladesh_amr.rds")
bd_genomic  <- readRDS("data/processed/bd_genomic.rds")
sa_genomic  <- readRDS("data/processed/sa_genomic.rds")

# ── Shared constants ──────────────────────────────────────────
ab_choices <- c(
  "MDR"              = "pct_mdr",
  "Ciprofloxacin NS" = "pct_cip_ns",
  "Ceftriaxone"      = "pct_cef",
  "Azithromycin"     = "pct_azi",
  "Ampicillin"       = "pct_amp",
  "Chloramphenicol"  = "pct_chl",
  "Cotrimoxazole"    = "pct_cot"
)
ab_choices <- ab_choices[ab_choices %in% names(bangladesh)]

country_pal <- c(
  Bangladesh = "#d7191c",
  Pakistan   = "#2c7bb6",
  India      = "#1a9641",
  Nepal      = "#f4a442"
)

# ── UI ────────────────────────────────────────────────────────
ui <- page_navbar(
  title   = " Typhoid Fever AMR Dashboard — Bangladesh",
  theme   = bs_theme(bootswatch = "flatly", primary = "#1a2f5a"),
  bg      = "#1a2f5a",
  inverse = TRUE,
  
  # Tab 1: Overview ─────────────────────────────────────────
  nav_panel("Overview",
            layout_columns(fill = FALSE, col_widths = c(3,3,3,3),
                           value_box("Total phenotypic isolates", textOutput("n_total"),      theme = "primary"),
                           value_box("Cipro NS — latest year",    textOutput("cipro_latest"), theme = "danger"),
                           value_box("MDR — latest year",         textOutput("mdr_latest"),   theme = "info"),
                           value_box("WGS isolates (Bangladesh)", textOutput("n_wgs"),        theme = "secondary")
            ),
            card(
              card_header("24-Year Phenotypic AMR Trends — Bangladesh (Tanmoy et al. 2024)"),
              plotlyOutput("main_trend", height = "420px")
            ),
            layout_columns(col_widths = c(6,6),
                           card(card_header("Data — Phenotypic Layer"),
                                markdown("**Tanmoy AM et al. (2024)** PLOS NTDs 18(10): e0012558  
12,435 culture-confirmed isolates · Dhaka · 1999–2022")),
                           card(card_header("Data — Genomic Layer"),
                                markdown("**TyphiNET Database**  
1,664 WGS isolates · Bangladesh · Dashboard-quality filter"))
            )
  ),
  
  # Tab 2: Phenotypic Trends ────────────────────────────────
  nav_panel("Phenotypic Trends",
            layout_sidebar(
              sidebar = sidebar(
                checkboxGroupInput("sel_ab", "Select antibiotics:",
                                   choices  = ab_choices,
                                   selected = names(ab_choices)[1:4]),
                sliderInput("yr", "Year range:",
                            min   = min(bangladesh$year),
                            max   = max(bangladesh$year),
                            value = c(min(bangladesh$year), max(bangladesh$year)),
                            sep   = "", step = 1)
              ),
              card(plotlyOutput("custom_trend", height = "430px")),
              layout_columns(col_widths = c(6,6),
                             card(card_header("Summary"),            tableOutput("trend_tbl")),
                             card(card_header("First vs Latest Year"), tableOutput("fl_tbl"))
              )
            )
  ),
  
  # Tab 3: Genomic Analysis ─────────────────────────────────
  nav_panel("Genomic Analysis",
            layout_columns(col_widths = c(12),
                           card(card_header("Two Layers — Same Story"),
                                markdown("Phenotypic data shows **what** is happening.  
Genomic data (TyphiNET) shows **why** — the mutations driving resistance."))
            ),
            layout_columns(col_widths = c(6,6),
                           card(card_header("Ciprofloxacin: CipNS vs CipR Over Time"),
                                plotlyOutput("cip_escalation", height = "380px")),
                           card(card_header("gyrA Mutation Landscape"),
                                plotlyOutput("gyra_plot",      height = "380px"))
            ),
            card(
              card_header("Genotype Distribution in Bangladesh"),
              plotlyOutput("genotype_plot", height = "340px")
            )
  ),
  
  # Tab 4: South Asia Comparison ────────────────────────────
  nav_panel("South Asia",
            layout_sidebar(
              sidebar = sidebar(
                radioButtons("sa_metric", "Show metric:",
                             choices = c(
                               "Cipro NS"      = "cip_ns",
                               "Cipro R"       = "cip_r",
                               "Ceftriaxone R" = "cef_r",
                               "XDR"           = "is_xdr",
                               "MDR"           = "is_mdr"
                             ), selected = "cip_ns"),
                helpText("Source: TyphiNET Database")
              ),
              card(
                card_header("South Asia AMR Comparison"),
                plotlyOutput("sa_trend", height = "440px")
              )
            )
  ),
  
  # Tab 5: Raw Data ─────────────────────────────────────────
  nav_panel("Raw Data",
            navset_tab(
              nav_panel("Phenotypic (Tanmoy)",
                        card(DTOutput("raw_pheno"))),
              nav_panel("Genomic Bangladesh (TyphiNET)",
                        card(DTOutput("raw_genomic")))
            )
  ),
  
  # Tab 6: About ────────────────────────────────────────────
  nav_panel("About",
            card(markdown("
## Typhoid Fever AMR Dashboard — Bangladesh

**Phenotypic Layer:** Tanmoy AM et al. (2024) — 12,435 isolates (1999–2022)  
**Genomic Layer:** TyphiNET Database — 1,664 WGS isolates (Bangladesh)

**Main Finding:** While **MDR has significantly declined** over 24 years,
**ciprofloxacin non-susceptibility remains extremely high (>90%)**.
Emerging azithromycin resistance and gradual increase in ceftriaxone MICs
are concerning signals for the future.
This project reproduces Tanmoy et al. (2024) and adds genomic context to
better understand the molecular drivers behind the observed resistance patterns.

**Repository:** [GitHub](https://github.com/mdabrarfaiyaj/Typhoid-Fever-in-Bangladesh)
"))
  )
)

# ── Server ────────────────────────────────────────────────────
server <- function(input, output, session) {
  
  # Value boxes
  output$n_total     <- renderText(format(sum(bangladesh$n_total, na.rm = TRUE), big.mark = ","))
  output$n_wgs       <- renderText(format(nrow(bd_genomic), big.mark = ","))
  
  latest <- bangladesh %>% filter(year == max(year))
  output$cipro_latest <- renderText(paste0(round(latest$pct_cip_ns, 1), "%"))
  output$mdr_latest   <- renderText(paste0(round(latest$pct_mdr, 1), "%"))
  
  # Main overview trend
  output$main_trend <- renderPlotly({
    cols <- intersect(c("pct_mdr","pct_cip_ns","pct_cef","pct_azi"), names(bangladesh))
    d <- bangladesh %>%
      select(year, all_of(cols)) %>%
      pivot_longer(-year, names_to = "m", values_to = "pct") %>%
      filter(!is.na(pct)) %>%
      mutate(label = recode(m,
                            pct_mdr    = "MDR",
                            pct_cip_ns = "Cipro NS",
                            pct_cef    = "Ceftriaxone",
                            pct_azi    = "Azithromycin"))
    plot_ly(d, x = ~year, y = ~pct, color = ~label,
            type = "scatter", mode = "lines+markers",
            colors = c("#2c7bb6","#d7191c","#f4a442","#7b2d8b")) %>%
      layout(xaxis     = list(title = "Year"),
             yaxis     = list(title = "% of isolates", range = c(0,105)),
             hovermode = "x unified",
             legend    = list(orientation = "h", y = -0.15))
  })
  
  # Custom phenotypic trend
  output$custom_trend <- renderPlotly({
    req(length(input$sel_ab) > 0)
    d <- bangladesh %>%
      filter(between(year, input$yr[1], input$yr[2])) %>%
      select(year, all_of(input$sel_ab)) %>%
      pivot_longer(-year, names_to = "m", values_to = "pct") %>%
      filter(!is.na(pct))
    plot_ly(d, x = ~year, y = ~pct, color = ~m,
            type = "scatter", mode = "lines+markers") %>%
      layout(hovermode = "x unified",
             yaxis     = list(title = "% of isolates"))
  })
  
  output$trend_tbl <- renderTable({
    req(length(input$sel_ab) > 0)
    bangladesh %>%
      select(year, all_of(input$sel_ab)) %>%
      pivot_longer(-year, names_to = "ab", values_to = "pct") %>%
      group_by(ab) %>%
      summarise(Mean = round(mean(pct, na.rm = TRUE), 1),
                Min  = round(min(pct,  na.rm = TRUE), 1),
                Max  = round(max(pct,  na.rm = TRUE), 1),
                .groups = "drop")
  })
  
  output$fl_tbl <- renderTable({
    req(length(input$sel_ab) > 0)
    bangladesh %>%
      filter(year %in% c(min(year), max(year))) %>%
      select(Year = year, all_of(input$sel_ab))
  })
  
  # CipNS vs CipR escalation
  output$cip_escalation <- renderPlotly({
    d <- bd_genomic %>%
      filter(!is.na(year)) %>%
      group_by(year) %>%
      summarise(
        n     = n(),
        cipNS = mean(cip_ns, na.rm = TRUE) * 100,
        cipR  = mean(cip_r,  na.rm = TRUE) * 100,
        .groups = "drop"
      ) %>%
      filter(n >= 5) %>%
      pivot_longer(c(cipNS, cipR), names_to = "level", values_to = "pct") %>%
      mutate(level = recode(level, "cipNS" = "CipNS (any)", "cipR" = "CipR (full)"))
    plot_ly(d, x = ~year, y = ~pct, color = ~level,
            type = "scatter", mode = "lines+markers",
            colors = c("#f4a442","#d7191c")) %>%
      layout(xaxis     = list(title = "Year"),
             yaxis     = list(title = "% of WGS isolates", range = c(0,105)),
             hovermode = "x unified",
             legend    = list(orientation = "h", y = -0.2))
  })
  
  # gyrA mutation bar chart
  output$gyra_plot <- renderPlotly({
    # Only use columns that actually exist in this dataset
    gyr_cols <- intersect(
      c("gyrA_S83F","gyrA_S83Y","gyrA_D87N","parC_E84K","acrB_R717Q"),
      names(bd_genomic)
    )
    if (length(gyr_cols) == 0) {
      return(plotly_empty() %>%
               layout(title = "Mutation columns not found in TyphiNET data"))
    }
    d <- bd_genomic %>%
      select(all_of(gyr_cols)) %>%
      summarise(across(everything(), ~round(mean(as.numeric(.), na.rm = TRUE) * 100, 1))) %>%
      pivot_longer(everything(), names_to = "mutation", values_to = "pct") %>%
      arrange(desc(pct))
    plot_ly(d, x = ~pct, y = ~mutation, type = "bar", orientation = "h",
            marker = list(color = "#d7191c")) %>%
      layout(xaxis = list(title = "% of Bangladesh WGS isolates", range = c(0,100)),
             yaxis = list(title = NULL))
  })
  
  # Genotype distribution
  output$genotype_plot <- renderPlotly({
    d <- bd_genomic %>%
      count(genotype) %>%
      arrange(desc(n)) %>%
      head(12) %>%
      mutate(genotype = fct_reorder(genotype, n))
    plot_ly(d, x = ~n, y = ~genotype, type = "bar", orientation = "h",
            marker = list(color = "#2c7bb6")) %>%
      layout(xaxis = list(title = "Number of WGS isolates"),
             yaxis = list(title = NULL))
  })
  
  # South Asia trend
  output$sa_trend <- renderPlotly({
    col <- input$sa_metric
    if (!col %in% names(sa_genomic)) {
      return(plotly_empty() %>%
               layout(title = paste("Column", col, "not found in data")))
    }
    d <- sa_genomic %>%
      filter(!is.na(year)) %>%
      group_by(country, year) %>%
      summarise(
        pct = mean(as.numeric(!!sym(col)), na.rm = TRUE) * 100,
        n   = n(),
        .groups = "drop"
      ) %>%
      filter(n >= 5)
    avail <- intersect(names(country_pal), unique(d$country))
    plot_ly(d, x = ~year, y = ~pct, color = ~country,
            type = "scatter", mode = "lines+markers",
            colors = unname(country_pal[avail])) %>%
      layout(xaxis     = list(title = "Year"),
             yaxis     = list(title = paste0("% ", col), range = c(0,105)),
             hovermode = "x unified",
             legend    = list(orientation = "h", y = -0.15))
  })
  
  # Raw data tables
  output$raw_pheno <- renderDT(
    datatable(bangladesh,
              filter  = "top",
              options = list(pageLength = 15, scrollX = TRUE),
              rownames = FALSE)
  )
  
  output$raw_genomic <- renderDT({
    # Only select columns that actually exist — safe against schema differences
    safe_cols <- intersect(
      c("year","genotype","cip_cat","cip_ns","cip_r","cef_r",
        "is_mdr","is_xdr","gyrA_S83F","acrB_R717Q"),
      names(bd_genomic)
    )
    datatable(bd_genomic %>% select(all_of(safe_cols)),
              filter  = "top",
              options = list(pageLength = 15, scrollX = TRUE),
              rownames = FALSE)
  })
}

shinyApp(ui, server)
