# ==============================================================================
#  ESTABLO SAUSALITO - Dashboard Mastitis
#  VERSION CORREGIDA PARA SHINYAPPS.IO
#
#  ESTRUCTURA OBLIGATORIA DE CARPETA:
#  app/
#  |-- app.R                  <- este archivo
#  |-- vacas_mastitis.csv     <- CSV en la MISMA carpeta (NO en subcarpeta)
#
#  PARA SUBIR (solo en consola de RStudio, NUNCA dentro del app.R):
#  library(rsconnect)
#  rsconnect::deployApp("ruta/a/tu/carpeta/app")
# ==============================================================================

# FIX 1: rsconnect NO va aqui. Solo estas librerias:
library(shiny)
library(shinydashboard)
library(shinyWidgets)
library(ggplot2)
library(plotly)
library(dplyr)
library(tidyr)
library(stringr)
library(lubridate)
library(DT)
library(readr)
library(scales)

# FIX 2: Ruta simple, sin file.path("data", ...), el CSV va junto al app.R
df_raw <- read_csv("vacas_mastitis.csv", show_col_types = FALSE)

# FIX 3: Limpieza sin caracteres especiales problematicos
df <- df_raw %>%
  filter(!str_detect(linea, "^----"), !is.na(vaca_id)) %>%
  mutate(
    vaca_id     = as.character(vaca_id),
    fecha       = suppressWarnings(as.Date(fecha)),
    dias        = suppressWarnings(as.numeric(dias)),
    edad        = suppressWarnings(as.numeric(edad)),
    lactacion   = suppressWarnings(as.numeric(lactacion)),
    produccion  = suppressWarnings(as.numeric(produccion)),
    tipo_evento = case_when(
      tipo_evento %in% c("PI","AD","PD","SI") ~ tipo_evento,
      TRUE ~ "Otro"
    ),
    tipo_evento = factor(tipo_evento, levels = c("PI","AD","PD","SI","Otro")),
    ano         = year(fecha),
    mes_num     = month(fecha),
    # FIX 3: sin tildes en labels
    mes_lbl = factor(
      month(fecha),
      levels = 1:12,
      labels = c("Ene","Feb","Mar","Abr","May","Jun",
                 "Jul","Ago","Sep","Oct","Nov","Dic")
    ),
    grupo_edad = cut(
      edad,
      breaks = c(0, 4, 6, 8, Inf),
      labels = c("< 4 anios", "4-6 anios", "6-8 anios", "8+ anios"),
      right  = FALSE
    )
  ) %>%
  arrange(vaca_id, fecha) %>%
  group_by(vaca_id) %>%
  mutate(
    n_evento_vaca      = row_number(),
    dias_entre_eventos = as.numeric(difftime(fecha, lag(fecha), units = "days"))
  ) %>%
  ungroup()

resumen_vaca <- df %>%
  group_by(vaca_id) %>%
  summarise(
    total_eventos  = n(),
    edad           = first(na.omit(edad)),
    lactacion      = first(na.omit(lactacion)),
    produccion_dim = first(na.omit(produccion)),
    primer_evento  = suppressWarnings(min(fecha, na.rm = TRUE)),
    ultimo_evento  = suppressWarnings(max(fecha, na.rm = TRUE)),
    tipo_mas_frec  = {
      t <- table(tipo_evento[!is.na(tipo_evento)])
      if (length(t) > 0) names(sort(t, decreasing = TRUE))[1] else "-"
    },
    .groups = "drop"
  ) %>%
  mutate(
    # FIX 3: sin tildes - "Critico" no "Crítico"
    riesgo = case_when(
      total_eventos >= 8 ~ "Critico",
      total_eventos >= 5 ~ "Alto",
      total_eventos >= 3 ~ "Medio",
      TRUE               ~ "Bajo"
    ),
    riesgo = factor(riesgo, levels = c("Critico","Alto","Medio","Bajo"))
  )

# Paleta de colores
PAL <- list(
  verde_osc = "#1a4a2e", verde_med = "#2d7a4e",
  verde_cla = "#4caf72", verde_pal = "#a8d5b5",
  ambar = "#f5a623", rojo = "#d94f3b",
  azul = "#3a7bd5", teal = "#2a9d8f", gris = "#6c757d"
)

COLS_TIPO <- c(
  "PI" = "#2d7a4e", "AD" = "#d94f3b",
  "PD" = "#f5a623", "SI" = "#3a7bd5", "Otro" = "#6c757d"
)

COLS_RIESGO <- c(
  "Critico" = "#7b2d8b", "Alto" = "#d94f3b",
  "Medio" = "#f5a623",   "Bajo" = "#4caf72"
)

tema_ss <- function() {
  theme_minimal(base_family = "sans") +
    theme(
      plot.background  = element_rect(fill = "#ffffff", color = NA),
      panel.background = element_rect(fill = "#ffffff", color = NA),
      panel.grid.major = element_line(color = "#e8f0ea", linewidth = 0.5),
      panel.grid.minor = element_blank(),
      axis.text        = element_text(color = "#3d5a42", size = 10),
      axis.title       = element_text(color = "#1c2b1e", size = 11, face = "bold"),
      legend.position  = "bottom",
      legend.text      = element_text(size = 9),
      strip.text       = element_text(face = "bold", color = "#1a4a2e", size = 10),
      strip.background = element_rect(fill = "#e8f5ec", color = NA)
    )
}

css <- "
@import url('https://fonts.googleapis.com/css2?family=Syne:wght@600;700;800&family=DM+Sans:wght@300;400;500;600&display=swap');

body, .content-wrapper, .right-side {
  font-family: 'DM Sans', sans-serif !important;
  background-color: #f4f7f2 !important;
}
.main-header .logo, .main-header .navbar {
  background: linear-gradient(135deg, #1a4a2e 0%, #2a5c3e 55%, #2d7a4e 100%) !important;
  border-bottom: none !important;
}
.main-header .logo {
  font-family: 'Syne', sans-serif !important;
  font-weight: 800 !important;
  font-size: 1rem !important;
  color: #ffffff !important;
}
.main-sidebar, .left-side { background-color: #1c3028 !important; }
.sidebar-menu > li > a {
  color: rgba(255,255,255,.72) !important;
  font-size: .84rem !important;
  padding: 10px 15px !important;
  border-left: 3px solid transparent !important;
  transition: all .18s !important;
}
.sidebar-menu > li.active > a,
.sidebar-menu > li > a:hover {
  background: rgba(255,255,255,.1) !important;
  color: #ffffff !important;
  border-left-color: #4caf72 !important;
}
.sidebar-menu > li > a > .fa { color: #a8d5b5 !important; margin-right: 8px !important; }
.sidebar-menu li.header {
  color: rgba(255,255,255,.38) !important;
  font-size: .67rem !important;
  font-weight: 700 !important;
  letter-spacing: .12em !important;
  padding: 14px 15px 6px !important;
}
.small-box {
  border-radius: 12px !important;
  box-shadow: 0 2px 14px rgba(30,70,40,.11) !important;
  transition: transform .18s, box-shadow .18s !important;
}
.small-box:hover { transform: translateY(-3px) !important; }
.small-box .inner h3 {
  font-family: 'Syne', sans-serif !important;
  font-weight: 800 !important;
  font-size: 2rem !important;
}
.small-box .inner p { font-size: .75rem !important; font-weight: 600 !important; }
.box {
  border-radius: 12px !important;
  box-shadow: 0 2px 12px rgba(30,70,40,.08) !important;
  border: 1.5px solid #dce8de !important;
}
.box-header {
  border-radius: 12px 12px 0 0 !important;
  padding: 12px 16px !important;
  background: #ffffff !important;
  border-bottom: 1px solid #e8f0ea !important;
}
.box-header .box-title {
  font-family: 'Syne', sans-serif !important;
  font-weight: 700 !important;
  font-size: .88rem !important;
  color: #1c2b1e !important;
}
.box.box-primary  { border-top: 3px solid #2d7a4e !important; }
.box.box-danger   { border-top: 3px solid #d94f3b !important; }
.box.box-warning  { border-top: 3px solid #f5a623 !important; }
.box.box-info     { border-top: 3px solid #3a7bd5 !important; }
.box.box-success  { border-top: 3px solid #4caf72 !important; }
.nav-tabs > li.active > a {
  color: #1a4a2e !important;
  border-bottom: 3px solid #2d7a4e !important;
  font-weight: 700 !important;
}
.nav-tabs > li > a { color: #6e8a72 !important; }
.selectize-input, .form-control {
  border-radius: 8px !important;
  border-color: #c8dece !important;
  font-size: .83rem !important;
}
.irs--shiny .irs-bar { background: #2d7a4e !important; border-color: #2d7a4e !important; }
.irs--shiny .irs-handle { background: #2d7a4e !important; border-color: #1a4a2e !important; }
.irs--shiny .irs-from, .irs--shiny .irs-to, .irs--shiny .irs-single { background: #1a4a2e !important; }
.dataTables_wrapper { font-size: .81rem !important; }
table.dataTable thead th {
  background: #1a4a2e !important;
  color: white !important;
  font-family: 'Syne', sans-serif !important;
  font-weight: 600 !important;
  font-size: .78rem !important;
}
table.dataTable tbody tr:hover td { background-color: #eef6f0 !important; }
.btn-primary, .btn-success {
  background: #2d7a4e !important;
  border-color: #2d7a4e !important;
  border-radius: 8px !important;
  font-weight: 600 !important;
}
.insight {
  background: linear-gradient(135deg, #e8f5ec, #f4faf6);
  border: 1.5px solid #b8ddc4;
  border-radius: 10px;
  padding: 11px 14px;
  margin-top: 10px;
  font-size: .8rem;
  color: #2d4a35;
  line-height: 1.6;
}
.insight strong { color: #1a4a2e; }
.insight.warn { background: #fff8ec; border-color: #f5d48a; color: #5a3e00; }
.insight.danger { background: #fdf0ee; border-color: #f0b8b0; color: #5c1a10; }
.ficha-stat {
  background: #f4f7f2;
  border-radius: 9px;
  padding: 9px 8px;
  text-align: center;
  margin-bottom: 7px;
}
.ficha-stat .st-lbl {
  font-size: .67rem; color: #6e8a72;
  font-weight: 600; text-transform: uppercase;
  letter-spacing: .07em; margin-bottom: 2px;
}
.ficha-stat .st-val {
  font-family: 'Syne', sans-serif;
  font-weight: 700; font-size: .95rem; color: #1c2b1e;
}
::-webkit-scrollbar { width: 6px; height: 6px; }
::-webkit-scrollbar-track { background: #f4f7f2; }
::-webkit-scrollbar-thumb { background: #a8d5b5; border-radius: 3px; }
"

# UI ────────────────────────────────────────────────────────────────────────────
ui <- dashboardPage(
  skin = "green",
  
  dashboardHeader(
    title = tags$span(
      style = "font-family:'Syne',sans-serif;font-weight:800;font-size:1rem",
      "SAUSALITO"
    ),
    tags$li(class = "dropdown",
            tags$a(href = "#",
                   style = "padding:18px 12px;color:rgba(255,255,255,.75);font-size:.78rem",
                   paste(nrow(df), "eventos |", n_distinct(df$vaca_id), "vacas")
            )
    )
  ),
  
  dashboardSidebar(
    width = 230,
    sidebarMenu(
      id = "tabs",
      menuItem("Resumen General",   tabName = "tab_resumen",   icon = icon("chart-pie")),
      menuItem("Analisis Mastitis", tabName = "tab_mastitis",  icon = icon("bug")),
      menuItem("Tendencias",        tabName = "tab_tendencia", icon = icon("chart-line")),
      menuItem("Perfil por Vaca",   tabName = "tab_vaca",      icon = icon("user")),
      menuItem("Tabla Completa",    tabName = "tab_tabla",     icon = icon("table")),
      
      tags$li(class = "header", "FILTROS"),
      
      tags$li(style = "padding: 0 12px 6px",
              pickerInput("f_tipo", "Tipo de Evento:",
                          choices  = c("Todos","PI","AD","PD","SI","Otro"),
                          selected = "Todos",
                          options  = list(style = "btn-sm btn-success btn-block")
              )
      ),
      tags$li(style = "padding: 0 12px 6px",
              sliderInput("f_ano", "Anios:",
                          min   = min(df$ano, na.rm = TRUE),
                          max   = max(df$ano, na.rm = TRUE),
                          value = c(min(df$ano, na.rm = TRUE), max(df$ano, na.rm = TRUE)),
                          step = 1, sep = "", ticks = FALSE
              )
      ),
      tags$li(style = "padding: 0 12px 6px",
              pickerInput("f_lact", "Lactacion:",
                          choices  = c("Todas", as.character(sort(unique(na.omit(df$lactacion))))),
                          selected = "Todas",
                          options  = list(style = "btn-sm btn-success btn-block")
              )
      ),
      tags$li(style = "padding: 0 12px 12px",
              pickerInput("f_edad", "Grupo de Edad:",
                          choices  = c("Todos", levels(df$grupo_edad)),
                          selected = "Todos",
                          options  = list(style = "btn-sm btn-success btn-block")
              )
      )
    )
  ),
  
  dashboardBody(
    tags$head(
      tags$style(HTML(css)),
      tags$link(rel = "stylesheet",
                href = "https://fonts.googleapis.com/css2?family=Syne:wght@600;700;800&family=DM+Sans:wght@300;400;500;600&display=swap"
      )
    ),
    
    tabItems(
      
      # TAB 1: RESUMEN
      tabItem(tabName = "tab_resumen",
              fluidRow(
                valueBoxOutput("kpi_eventos",  width = 2),
                valueBoxOutput("kpi_vacas",    width = 2),
                valueBoxOutput("kpi_pi",       width = 2),
                valueBoxOutput("kpi_ad",       width = 2),
                valueBoxOutput("kpi_critico",  width = 2),
                valueBoxOutput("kpi_prom",     width = 2)
              ),
              fluidRow(
                box(title = "Eventos por Tipo de Mastitis",
                    status = "primary", width = 4,
                    plotlyOutput("g_donut_tipo", height = "260px"),
                    div(class = "insight",
                        tags$strong("PI"), " = Pezon Izq. | ",
                        tags$strong("AD"), " = Ant. Der. | ",
                        tags$strong("PD"), " = Pezon Der. | ",
                        tags$strong("SI"), " = Sin Identificar | ",
                        tags$strong("Otro"), " = No catalogado"
                    )
                ),
                box(title = "Eventos por Numero de Lactacion",
                    status = "primary", width = 4,
                    plotlyOutput("g_lact", height = "260px")
                ),
                box(title = "Vacas por Nivel de Riesgo",
                    status = "danger", width = 4,
                    plotlyOutput("g_riesgo", height = "260px"),
                    div(class = "insight warn",
                        tags$strong("Critico:"), " >= 8 eventos | ",
                        tags$strong("Alto:"),    " 5-7 | ",
                        tags$strong("Medio:"),   " 3-4 | ",
                        tags$strong("Bajo:"),    " 1-2"
                    )
                )
              ),
              fluidRow(
                box(title = "Mapa de Calor - Frecuencia Mensual por Anio",
                    status = "primary", width = 8,
                    plotlyOutput("g_heatmap", height = "230px")
                ),
                box(title = "Top Vacas con Mas Eventos",
                    status = "warning", width = 4,
                    plotlyOutput("g_top_vacas", height = "230px")
                )
              )
      ),
      
      # TAB 2: MASTITIS
      tabItem(tabName = "tab_mastitis",
              fluidRow(
                box(title = "Frecuencia por Tipo de Evento",
                    status = "danger", width = 6,
                    plotlyOutput("g_freq", height = "280px")
                ),
                box(title = "Distribucion de Dias Relativos al Parto",
                    status = "info", width = 6,
                    plotlyOutput("g_boxplot", height = "280px"),
                    div(class = "insight",
                        "Dias negativos = antes del parto. ",
                        tags$strong("Concentracion cerca de 0"), " indica mastitis periparto."
                    )
                )
              ),
              fluidRow(
                box(title = "Edad vs. Total de Eventos por Vaca",
                    status = "primary", width = 5,
                    plotlyOutput("g_scatter", height = "280px")
                ),
                box(title = "Top 12 Tratamientos Mas Utilizados",
                    status = "success", width = 7,
                    plotlyOutput("g_tratam", height = "280px")
                )
              ),
              fluidRow(
                box(title = "Composicion de Tipos por Lactacion (100% apilado)",
                    status = "primary", width = 12,
                    plotlyOutput("g_mosaico", height = "240px"),
                    div(class = "insight",
                        tags$strong("AD dominante en lactaciones altas"),
                        " puede indicar desgaste estructural de la ubre."
                    )
                )
              )
      ),
      
      # TAB 3: TENDENCIAS
      tabItem(tabName = "tab_tendencia",
              fluidRow(
                box(title = "Serie Temporal - Eventos por Mes con Tendencia LOESS",
                    status = "primary", width = 12,
                    plotlyOutput("g_serie", height = "290px"),
                    div(class = "insight",
                        tags$strong("Linea verde suavizada (LOESS)"),
                        " = tendencia general del hato. Picos indican posibles brotes."
                    )
                )
              ),
              fluidRow(
                box(title = "Estacionalidad - Promedio por Mes del Anio",
                    status = "info", width = 6,
                    plotlyOutput("g_estacion", height = "260px")
                ),
                box(title = "Comparativa Anual por Tipo",
                    status = "warning", width = 6,
                    plotlyOutput("g_anual", height = "260px")
                )
              ),
              fluidRow(
                box(title = "Intervalo Mediano Entre Eventos (Top Vacas Recurrentes)",
                    status = "success", width = 12,
                    plotlyOutput("g_intervalos", height = "260px"),
                    div(class = "insight danger",
                        tags$strong("Intervalos < 60 dias"),
                        " entre eventos sucesivos = mastitis cronica. Evaluar para tratamiento intensivo."
                    )
                )
              )
      ),
      
      # TAB 4: PERFIL POR VACA
      tabItem(tabName = "tab_vaca",
              fluidRow(
                box(title = "Seleccionar Vaca",
                    status = "primary", width = 3,
                    pickerInput("sel_vaca", label = NULL,
                                choices  = sort(unique(df$vaca_id)),
                                selected = sort(unique(df$vaca_id))[1],
                                options  = list(`live-search` = TRUE, style = "btn-success btn-block")
                    ),
                    hr(style = "border-color:#dce8de;margin:10px 0"),
                    uiOutput("ficha_vaca")
                ),
                box(title = "Historial de Eventos - Timeline",
                    status = "info", width = 9,
                    plotlyOutput("g_timeline", height = "230px"),
                    hr(style = "border-color:#dce8de;margin:10px 0"),
                    DTOutput("tbl_vaca")
                )
              )
      ),
      
      # TAB 5: TABLA COMPLETA
      tabItem(tabName = "tab_tabla",
              fluidRow(
                box(title = "Dataset Completo - Mastitis Establo Sausalito",
                    status = "primary", width = 12,
                    div(style = "margin-bottom:10px;display:flex;gap:8px",
                        downloadButton("dl_csv", "Descargar CSV", class = "btn-primary btn-sm"),
                        div(style = "margin-left:auto;font-size:.78rem;color:#6e8a72;padding-top:6px",
                            textOutput("n_filas_txt", inline = TRUE)
                        )
                    ),
                    DTOutput("tbl_completa")
                )
              )
      )
    )
  )
)

# SERVER ────────────────────────────────────────────────────────────────────────
server <- function(input, output, session) {
  
  df_f <- reactive({
    d <- df
    if (!is.null(input$f_tipo) && input$f_tipo != "Todos")
      d <- d %>% filter(tipo_evento == input$f_tipo)
    if (!is.null(input$f_ano))
      d <- d %>% filter(!is.na(ano), ano >= input$f_ano[1], ano <= input$f_ano[2])
    if (!is.null(input$f_lact) && input$f_lact != "Todas")
      d <- d %>% filter(!is.na(lactacion), lactacion == as.numeric(input$f_lact))
    if (!is.null(input$f_edad) && input$f_edad != "Todos")
      d <- d %>% filter(!is.na(grupo_edad), as.character(grupo_edad) == input$f_edad)
    d
  })
  
  rv_f <- reactive({
    resumen_vaca %>% filter(vaca_id %in% unique(df_f()$vaca_id))
  })
  
  ly <- function(p) {
    p %>% layout(
      paper_bgcolor = "rgba(0,0,0,0)",
      plot_bgcolor  = "rgba(0,0,0,0)",
      font   = list(family = "DM Sans, sans-serif", color = "#3d5a42"),
      legend = list(orientation = "h", y = -0.18, font = list(size = 11)),
      margin = list(t = 10, b = 30, l = 40, r = 20)
    )
  }
  
  # KPIs
  output$kpi_eventos <- renderValueBox(valueBox(
    nrow(df_f()), "Total Eventos", icon = icon("bug"), color = "green"))
  output$kpi_vacas <- renderValueBox(valueBox(
    n_distinct(df_f()$vaca_id), "Vacas Afectadas", icon = icon("cow"), color = "teal"))
  output$kpi_pi <- renderValueBox(valueBox(
    sum(df_f()$tipo_evento == "PI", na.rm=TRUE), "Eventos PI", icon = icon("stethoscope"), color = "green"))
  output$kpi_ad <- renderValueBox(valueBox(
    sum(df_f()$tipo_evento == "AD", na.rm=TRUE), "Eventos AD", icon = icon("exclamation-circle"), color = "red"))
  output$kpi_critico <- renderValueBox(valueBox(
    sum(rv_f()$riesgo %in% c("Critico","Alto"), na.rm=TRUE),
    "Vacas Riesgo Alto/Critico", icon = icon("exclamation-triangle"), color = "red"))
  output$kpi_prom <- renderValueBox(valueBox(
    round(mean(rv_f()$total_eventos, na.rm=TRUE), 1),
    "Prom. Eventos / Vaca", icon = icon("chart-bar"), color = "yellow"))
  
  # TAB RESUMEN
  output$g_donut_tipo <- renderPlotly({
    d <- df_f() %>% count(tipo_evento) %>% filter(n > 0)
    plot_ly(d,
            labels = ~tipo_evento, values = ~n, type = "pie", hole = 0.58,
            marker = list(colors = unname(COLS_TIPO[as.character(d$tipo_evento)]),
                          line = list(color = "#fff", width = 2)),
            textinfo = "label+percent",
            hovertemplate = "<b>%{label}</b><br>%{value} eventos (%{percent})<extra></extra>"
    ) %>% ly()
  })
  
  output$g_lact <- renderPlotly({
    d <- df_f() %>% filter(!is.na(lactacion)) %>%
      count(lactacion) %>% mutate(lbl = paste0(lactacion, "a"))
    pal <- colorRampPalette(c(PAL$verde_osc, PAL$verde_cla))(max(nrow(d),1))
    plot_ly(d, x = ~lbl, y = ~n, type = "bar",
            marker = list(color = pal, line = list(color = "#fff", width = 1)),
            text = ~n, textposition = "outside",
            hovertemplate = "%{x}: <b>%{y}</b> eventos<extra></extra>"
    ) %>% layout(
      xaxis = list(title = "Lactacion", gridcolor = "#e8f0ea"),
      yaxis = list(title = "N Eventos", gridcolor = "#e8f0ea")
    ) %>% ly()
  })
  
  output$g_riesgo <- renderPlotly({
    d <- rv_f() %>% count(riesgo) %>% filter(!is.na(riesgo))
    plot_ly(d,
            labels = ~riesgo, values = ~n, type = "pie", hole = 0.62,
            marker = list(colors = unname(COLS_RIESGO[as.character(d$riesgo)]),
                          line = list(color = "#fff", width = 2)),
            textinfo = "label+value",
            hovertemplate = "<b>%{label}</b>: %{value} vacas<extra></extra>"
    ) %>% ly()
  })
  
  output$g_heatmap <- renderPlotly({
    d <- df_f() %>% filter(!is.na(fecha)) %>%
      count(ano, mes_num) %>%
      mutate(mes_lbl = factor(mes_num, levels=1:12,
                              labels=c("Ene","Feb","Mar","Abr","May","Jun","Jul","Ago","Sep","Oct","Nov","Dic")))
    plot_ly(d,
            x = ~mes_lbl, y = ~factor(ano), z = ~n,
            type = "heatmap",
            colorscale = list(list(0,"#e8f5ec"), list(0.4,PAL$verde_cla),
                              list(0.75,PAL$verde_med), list(1,PAL$verde_osc)),
            hovertemplate = "Mes: %{x} | Anio: %{y}<br><b>%{z} eventos</b><extra></extra>",
            showscale = TRUE
    ) %>% layout(
      xaxis = list(title = "Mes"), yaxis = list(title = "Anio")
    ) %>% ly()
  })
  
  output$g_top_vacas <- renderPlotly({
    d <- df_f() %>% count(vaca_id, sort=TRUE) %>% slice_head(n=10) %>%
      mutate(vaca_id = factor(vaca_id, levels=rev(vaca_id)),
             color = colorRampPalette(c(PAL$ambar, PAL$rojo))(10))
    plot_ly(d, x = ~n, y = ~vaca_id, type = "bar", orientation = "h",
            marker = list(color = ~color, line = list(color="#fff", width=1)),
            text = ~n, textposition = "outside",
            hovertemplate = "Vaca <b>%{y}</b>: %{x} eventos<extra></extra>"
    ) %>% layout(
      xaxis = list(title = "N Eventos", gridcolor="#e8f0ea"),
      yaxis = list(title = "")
    ) %>% ly()
  })
  
  # TAB MASTITIS
  output$g_freq <- renderPlotly({
    d <- df_f() %>% count(tipo_evento) %>% mutate(pct = round(n/sum(n)*100,1))
    plot_ly(d, x = ~tipo_evento, y = ~n, type = "bar",
            marker = list(color = unname(COLS_TIPO[as.character(d$tipo_evento)]),
                          line = list(color="#fff", width=1.5)),
            text = ~paste0(n," (",pct,"%)"), textposition = "outside",
            hovertemplate = "<b>%{x}</b>: %{y} eventos<extra></extra>"
    ) %>% layout(
      xaxis = list(title = "Tipo"),
      yaxis = list(title = "Frecuencia", gridcolor="#e8f0ea")
    ) %>% ly()
  })
  
  output$g_boxplot <- renderPlotly({
    d <- df_f() %>% filter(!is.na(dias))
    plot_ly(d, x = ~tipo_evento, y = ~dias, type = "box",
            color = ~tipo_evento, colors = unname(COLS_TIPO[levels(df$tipo_evento)]),
            hovertemplate = "Tipo: <b>%{x}</b><br>Dias: %{y}<extra></extra>"
    ) %>% layout(
      xaxis = list(title = "Tipo"),
      yaxis = list(title = "Dias relativo al parto", gridcolor="#e8f0ea"),
      showlegend = FALSE
    ) %>% ly()
  })
  
  output$g_scatter <- renderPlotly({
    d <- rv_f() %>% filter(!is.na(edad))
    plot_ly(d, x = ~edad, y = ~total_eventos,
            color = ~riesgo, colors = COLS_RIESGO,
            size  = ~total_eventos, sizes = c(10, 50),
            type = "scatter", mode = "markers",
            text = ~paste0("Vaca: <b>",vaca_id,"</b>",
                           "<br>Edad: ",edad," anios",
                           "<br>Eventos: ",total_eventos,
                           "<br>Riesgo: ",riesgo),
            hoverinfo = "text"
    ) %>% layout(
      xaxis = list(title = "Edad (anios)", gridcolor="#e8f0ea"),
      yaxis = list(title = "N Total Eventos", gridcolor="#e8f0ea")
    ) %>% ly()
  })
  
  output$g_tratam <- renderPlotly({
    d <- df_f() %>%
      filter(!is.na(tratamiento), str_trim(tratamiento) != "") %>%
      mutate(tratamiento = str_squish(tratamiento)) %>%
      count(tratamiento, sort=TRUE) %>% slice_head(n=12) %>%
      mutate(tratamiento = str_trunc(tratamiento, 28))
    pal <- colorRampPalette(c(PAL$teal, PAL$verde_osc))(nrow(d))
    plot_ly(d, x = ~n, y = ~reorder(tratamiento, n), type = "bar", orientation = "h",
            marker = list(color=pal, line=list(color="#fff", width=1)),
            text = ~n, textposition = "outside",
            hovertemplate = "%{y}: <b>%{x}</b> usos<extra></extra>"
    ) %>% layout(
      xaxis = list(title = "Frecuencia", gridcolor="#e8f0ea"),
      yaxis = list(title = "", tickfont=list(size=9))
    ) %>% ly()
  })
  
  output$g_mosaico <- renderPlotly({
    d <- df_f() %>% filter(!is.na(lactacion)) %>%
      count(lactacion, tipo_evento) %>%
      group_by(lactacion) %>%
      mutate(pct = round(n/sum(n)*100, 1)) %>% ungroup() %>%
      mutate(lbl = paste0(lactacion, "a Lact."))
    plot_ly(d, x = ~lbl, y = ~pct, color = ~tipo_evento,
            colors = unname(COLS_TIPO[levels(df$tipo_evento)]),
            type = "bar", barmode = "stack",
            text = ~ifelse(pct >= 8, paste0(tipo_evento,": ",pct,"%"), ""),
            textposition = "inside",
            hovertemplate = "%{x} | <b>%{fullData.name}</b>: %{y:.1f}%<extra></extra>"
    ) %>% layout(
      xaxis = list(title = "Lactacion"),
      yaxis = list(title = "% del total", range=c(0,105), gridcolor="#e8f0ea")
    ) %>% ly()
  })
  
  # TAB TENDENCIAS
  output$g_serie <- renderPlotly({
    req(nrow(df_f() %>% filter(!is.na(fecha))) > 0)
    d <- df_f() %>% filter(!is.na(fecha)) %>%
      mutate(mes_ini = floor_date(fecha, "month")) %>%
      count(mes_ini, tipo_evento)
    d_total <- df_f() %>% filter(!is.na(fecha)) %>%
      mutate(mes_ini = floor_date(fecha, "month")) %>%
      count(mes_ini)
    p <- ggplot() +
      geom_col(data=d, aes(x=mes_ini, y=n, fill=tipo_evento),
               position="stack", alpha=0.82, width=20) +
      geom_smooth(data=d_total, aes(x=mes_ini, y=n),
                  method="loess", se=TRUE, span=0.45,
                  color=PAL$verde_osc, fill=PAL$verde_pal, alpha=0.25, linewidth=1.4) +
      scale_fill_manual(values=COLS_TIPO, name="Tipo") +
      scale_x_date(date_labels="%b %Y", date_breaks="3 months") +
      tema_ss() +
      theme(axis.text.x = element_text(angle=45, hjust=1, size=8)) +
      labs(x=NULL, y="N Eventos")
    ggplotly(p, tooltip=c("x","y","fill")) %>%
      layout(paper_bgcolor="rgba(0,0,0,0)", plot_bgcolor="rgba(0,0,0,0)",
             legend=list(orientation="h", y=-0.22))
  })
  
  output$g_estacion <- renderPlotly({
    req(nrow(df_f() %>% filter(!is.na(fecha))) > 0)
    d <- df_f() %>% filter(!is.na(fecha)) %>%
      count(ano, mes_num) %>%
      group_by(mes_num) %>%
      summarise(promedio=round(mean(n),2), .groups="drop") %>%
      mutate(mes_lbl = factor(mes_num, levels=1:12,
                              labels=c("Ene","Feb","Mar","Abr","May","Jun","Jul","Ago","Sep","Oct","Nov","Dic")))
    pal <- colorRampPalette(c(PAL$verde_pal, PAL$verde_osc))(12)
    plot_ly(d, x=~mes_lbl, y=~promedio, type="bar",
            marker=list(color=pal, line=list(color="#fff", width=1)),
            text=~round(promedio,1), textposition="outside",
            hovertemplate="%{x}: promedio <b>%{y:.1f}</b> eventos<extra></extra>"
    ) %>% layout(
      xaxis=list(title="Mes"),
      yaxis=list(title="Promedio eventos/mes", gridcolor="#e8f0ea")
    ) %>% ly()
  })
  
  output$g_anual <- renderPlotly({
    req(nrow(df_f() %>% filter(!is.na(fecha))) > 0)
    d <- df_f() %>% filter(!is.na(fecha)) %>% count(ano, tipo_evento)
    plot_ly(d, x=~factor(ano), y=~n, color=~tipo_evento,
            colors=unname(COLS_TIPO[levels(df$tipo_evento)]),
            type="bar", barmode="group",
            hovertemplate="Anio <b>%{x}</b> | %{fullData.name}: %{y} eventos<extra></extra>"
    ) %>% layout(
      xaxis=list(title="Anio"),
      yaxis=list(title="N Eventos", gridcolor="#e8f0ea")
    ) %>% ly()
  })
  
  output$g_intervalos <- renderPlotly({
    d <- df %>%
      filter(!is.na(dias_entre_eventos), dias_entre_eventos > 0) %>%
      group_by(vaca_id) %>%
      summarise(mediana_int=median(dias_entre_eventos, na.rm=TRUE),
                n_eventos=n(), .groups="drop") %>%
      filter(n_eventos >= 2) %>%
      arrange(mediana_int) %>% slice_head(n=15)
    req(nrow(d) > 0)
    plot_ly(d, x=~mediana_int, y=~reorder(vaca_id, mediana_int),
            type="bar", orientation="h",
            marker=list(
              color=~mediana_int,
              colorscale=list(list(0,PAL$rojo), list(0.4,PAL$ambar), list(1,PAL$verde_cla)),
              showscale=TRUE, colorbar=list(title="Dias", len=0.7)
            ),
            text=~paste0(round(mediana_int)," dias"), textposition="outside",
            hovertemplate=paste0("Vaca <b>%{y}</b><br>Mediana: <b>%{x:.0f} dias</b><extra></extra>")
    ) %>% layout(
      xaxis=list(title="Mediana dias entre eventos", gridcolor="#e8f0ea"),
      yaxis=list(title="Vaca ID", tickfont=list(size=10))
    ) %>% ly()
  })
  
  # TAB PERFIL VACA
  output$ficha_vaca <- renderUI({
    rv <- resumen_vaca %>% filter(vaca_id == input$sel_vaca)
    if (nrow(rv) == 0) return(tags$p("Sin datos para esta vaca."))
    cr <- COLS_RIESGO[as.character(rv$riesgo)]
    names(cr) <- NULL
    tags$div(
      tags$div(style="text-align:center;padding:8px 0 14px",
               tags$div(style="font-size:3rem;line-height:1", "cow"),
               tags$div(
                 style="font-family:'Syne',sans-serif;font-size:1.4rem;font-weight:800;color:#1a4a2e",
                 paste("Vaca", rv$vaca_id)
               ),
               tags$span(
                 style=paste0("display:inline-block;background:",cr,
                              ";color:white;border-radius:20px;padding:3px 14px;",
                              "font-size:.75rem;font-weight:700;margin-top:5px"),
                 paste("Riesgo", as.character(rv$riesgo))
               )
      ),
      tags$div(style="display:grid;grid-template-columns:1fr 1fr;gap:7px",
               lapply(
                 list(
                   list("Edad",         paste(rv$edad, "anios")),
                   list("Lactacion",    paste0(rv$lactacion, "a")),
                   list("N Eventos",    rv$total_eventos),
                   list("DIM (dias)",   rv$produccion_dim),
                   list("1er Evento",   format(rv$primer_evento, "%d/%m/%Y")),
                   list("Ultimo",       format(rv$ultimo_evento, "%d/%m/%Y")),
                   list("Tipo Frec.",   rv$tipo_mas_frec)
                 ),
                 function(x) {
                   tags$div(class="ficha-stat",
                            tags$div(class="st-lbl", x[[1]]),
                            tags$div(class="st-val", as.character(x[[2]]))
                   )
                 }
               )
      )
    )
  })
  
  output$g_timeline <- renderPlotly({
    d <- df %>% filter(vaca_id == input$sel_vaca, !is.na(fecha))
    if (nrow(d) == 0) return(plotly_empty())
    cols <- unname(COLS_TIPO[as.character(d$tipo_evento)])
    plot_ly(d, x=~fecha, y=~tipo_evento, type="scatter", mode="markers",
            marker=list(color=cols, size=14, line=list(color="#ffffff", width=2)),
            text=~paste0(format(fecha,"%d/%m/%Y"),
                         "<br>Tipo: <b>",tipo_evento,"</b>",
                         "<br>Dias: ",dias,
                         "<br>Trat.: ",ifelse(is.na(tratamiento),"N/D",str_trunc(tratamiento,30))),
            hoverinfo="text"
    ) %>% layout(
      xaxis=list(title="Fecha", gridcolor="#e8f0ea"),
      yaxis=list(title="Tipo"),
      showlegend=FALSE
    ) %>% ly()
  })
  
  output$tbl_vaca <- renderDT({
    df %>% filter(vaca_id == input$sel_vaca) %>%
      arrange(fecha) %>%
      transmute(
        Fecha=fecha, Tipo=as.character(tipo_evento),
        Tratamiento=tratamiento, "Dias rel."=dias,
        "Intervalo (dias)"=round(dias_entre_eventos,0), "N Evento"=n_evento_vaca
      ) %>%
      datatable(rownames=FALSE,
                options=list(pageLength=8, dom="tp",
                             language=list(url="//cdn.datatables.net/plug-ins/1.10.11/i18n/Spanish.json")),
                class="stripe hover compact"
      ) %>%
      formatStyle("Tipo",
                  backgroundColor=styleEqual(c("PI","AD","PD","SI","Otro"),
                                             c("#d4edda","#f8d7da","#fff3cd","#cce5ff","#e2e3e5")),
                  fontWeight="bold"
      )
  })
  
  # TAB TABLA
  output$n_filas_txt <- renderText({
    paste0(nrow(df_f()), " registros encontrados")
  })
  
  output$tbl_completa <- renderDT({
    df_f() %>%
      transmute(
        "Vaca ID"=vaca_id, Fecha=fecha,
        Tipo=as.character(tipo_evento), Tratamiento=tratamiento,
        "Dias"=dias, "Edad (anios)"=edad, "Lactacion"=lactacion,
        "DIM (dias)"=produccion, "Intervalo (dias)"=round(dias_entre_eventos,0),
        "Grupo Edad"=as.character(grupo_edad)
      ) %>%
      datatable(filter="top", rownames=FALSE,
                options=list(pageLength=15, scrollX=TRUE, dom="lfrtip",
                             language=list(url="//cdn.datatables.net/plug-ins/1.10.11/i18n/Spanish.json")),
                class="stripe hover compact"
      ) %>%
      formatStyle("Tipo",
                  backgroundColor=styleEqual(c("PI","AD","PD","SI","Otro"),
                                             c("#d4edda","#f8d7da","#fff3cd","#cce5ff","#e2e3e5")),
                  fontWeight="bold"
      )
  })
  
  output$dl_csv <- downloadHandler(
    filename=function() paste0("sausalito_", Sys.Date(), ".csv"),
    content=function(file) write_csv(df_f(), file)
  )
}

shinyApp(ui, server)
