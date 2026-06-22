# =============================================================================
#  AUTOCORRELACION ESPACIAL — INDICE DE MORAN
#  VERSION FINAL: leaflet puro (sin tmap), mapas garantizados en Windows
#  spdep + sf + leaflet + plotly + RMarkdown
# =============================================================================

library(shiny)
library(shinydashboard)
library(shinyjs)
library(shinyWidgets)
library(sf)
library(sp)
library(spdep)
library(leaflet)
library(leaflet.extras)
library(ggplot2)
library(plotly)
library(RColorBrewer)
library(viridis)
library(dplyr)
library(DT)
library(rmarkdown)
library(knitr)
library(spData)

# =============================================================================
# CARGA DE DATASETS
# =============================================================================
cargar_nc <- function() {
  tryCatch({
    nc_path <- system.file("shape/nc.shp", package = "sf")
    if (nc_path == "") stop("no encontrado")
    st_read(nc_path, quiet = TRUE)
  }, error = function(e) NULL)
}

cargar_us_states <- function() {
  tryCatch({
    e <- new.env()
    data("us_states", package = "spData", envir = e)
    sf_obj <- e$us_states
    sf_obj$total_pop_10     <- as.numeric(sf_obj$total_pop_10)
    sf_obj$total_pop_15     <- as.numeric(sf_obj$total_pop_15)
    sf_obj$median_income_10 <- as.numeric(sf_obj$median_income_10)
    sf_obj$median_income_15 <- as.numeric(sf_obj$median_income_15)
    sf_obj
  }, error = function(e) NULL)
}

cargar_world <- function() {
  tryCatch({
    e <- new.env()
    data("world", package = "spData", envir = e)
    w <- e$world
    w <- w[!is.na(w$gdpPercap) & !is.na(w$lifeExp), ]
    st_make_valid(w)
  }, error = function(e) NULL)
}

cargar_boston <- function() {
  tryCatch({
    e <- new.env()
    data("boston", package = "spData", envir = e)
    coords <- e$boston.utm
    df     <- as.data.frame(e$boston.c)
    for (col in c("MEDV","CRIM","NOX","RM","AGE","DIS"))
      df[[col]] <- as.numeric(df[[col]])
    df$x <- coords[, 1]
    df$y <- coords[, 2]
    sf_obj <- st_as_sf(df, coords = c("x","y"), crs = 26986)
    st_transform(sf_obj, 4326)
  }, error = function(e) NULL)
}

cargar_dataset <- function(nombre) {
  switch(nombre,
    "North Carolina (SIDS)" = {
      sf <- cargar_nc()
      if (is.null(sf)) stop("No se pudo cargar NC — verifica paquete 'sf'")
      list(sf = sf,
           vars = c("SID74","SID79","BIR74","BIR79","NWBIR74","NWBIR79"),
           titulo = "Carolina del Norte — Muertes infantiles (SIDS)",
           desc = "74 condados de Carolina del Norte con variables de nacimientos y muertes súbitas infantiles (SIDS) para 1974 y 1979.",
           tipo = "poly")
    },
    "US States (población)" = {
      sf <- cargar_us_states()
      if (is.null(sf)) stop("No se pudo cargar us_states — verifica 'spData'")
      list(sf = sf,
           vars = c("total_pop_10","total_pop_15","median_income_10","median_income_15"),
           titulo = "Estados Unidos — Población e ingresos",
           desc = "49 estados de EE.UU. con datos de población e ingreso mediano para 2010 y 2015.",
           tipo = "poly")
    },
    "Boston Housing (puntos)" = {
      sf <- cargar_boston()
      if (is.null(sf)) stop("No se pudo cargar Boston — verifica 'spData'")
      list(sf = sf,
           vars = c("MEDV","CRIM","NOX","RM","AGE","DIS"),
           titulo = "Boston — Valor de viviendas (Harrison & Rubinfeld, 1978)",
           desc = "506 zonas censales de Boston. MEDV=precio mediano, CRIM=crimen per cápita, NOX=contaminación, RM=habitaciones promedio.",
           tipo = "point")
    },
    "Mundo (desarrollo)" = {
      sf <- cargar_world()
      if (is.null(sf)) stop("No se pudo cargar world — verifica 'spData'")
      list(sf = sf,
           vars = c("gdpPercap","lifeExp","pop","area_km2"),
           titulo = "Mundo — Desarrollo humano",
           desc = "Países del mundo con PIB per cápita, esperanza de vida y población.",
           tipo = "poly")
    }
  )
}

DATASETS <- c("North Carolina (SIDS)","US States (población)",
               "Boston Housing (puntos)","Mundo (desarrollo)")

METODOS_W <- c(
  "Reina (Queen)"                = "queen",
  "Torre (Rook)"                 = "rook",
  "K vecinos más cercanos (KNN)" = "knn",
  "Distancia inversa"            = "dist"
)

# =============================================================================
# FUNCIONES DE ANÁLISIS
# =============================================================================
es_punto_sf <- function(sf_obj) {
  any(grepl("POINT", as.character(unique(st_geometry_type(sf_obj))), ignore.case = TRUE))
}

construir_W <- function(sf_data, metodo = "queen", k = 5) {
  es_punto <- es_punto_sf(sf_data)
  coords   <- st_coordinates(st_centroid(st_geometry(sf_data)))

  tryCatch({
    if (!es_punto && metodo == "queen") {
      nb <- poly2nb(sf_data, queen = TRUE)
      nb2listw(nb, style = "W", zero.policy = TRUE)
    } else if (!es_punto && metodo == "rook") {
      nb <- poly2nb(sf_data, queen = FALSE)
      nb2listw(nb, style = "W", zero.policy = TRUE)
    } else {
      nb <- knn2nb(knearneigh(coords, k = k))
      if (metodo == "dist") {
        dists <- nbdists(nb, coords)
        idw   <- lapply(dists, function(x) 1/x)
        nb2listw(nb, glist = idw, style = "B", zero.policy = TRUE)
      } else {
        nb2listw(nb, style = "W", zero.policy = TRUE)
      }
    }
  }, error = function(e) {
    nb <- knn2nb(knearneigh(coords, k = max(k, 3)))
    nb2listw(nb, style = "W", zero.policy = TRUE)
  })
}

calcular_moran_global <- function(x, W, nsim = 999) {
  xc <- as.numeric(x); xc[is.na(xc)] <- mean(xc, na.rm = TRUE)
  mt <- moran.test(xc, W, zero.policy = TRUE)
  mc <- moran.mc(xc, W, nsim = nsim, zero.policy = TRUE)
  I    <- as.numeric(mt$estimate["Moran I statistic"])
  EI   <- as.numeric(mt$estimate["Expectation"])
  VarI <- as.numeric(mt$estimate["Variance"])
  list(test = mt, mc = mc, I = I, EI = EI, VarI = VarI,
       p_value = mt$p.value, z_score = (I - EI)/sqrt(VarI), p_mc = mc$p.value)
}

calcular_moran_local <- function(x, W) {
  xc    <- as.numeric(x); xc[is.na(xc)] <- mean(xc, na.rm = TRUE)
  lisa  <- localmoran(xc, W, zero.policy = TRUE)
  xz    <- as.numeric(scale(xc))
  lagz  <- lag.listw(W, xz, zero.policy = TRUE)
  quad  <- rep("No significativo", length(xz))
  sig   <- lisa[,5] < 0.05
  quad[sig & xz >  0 & lagz >  0] <- "Alto-Alto (HH)"
  quad[sig & xz <  0 & lagz <  0] <- "Bajo-Bajo (LL)"
  quad[sig & xz >  0 & lagz <  0] <- "Alto-Bajo (HL)"
  quad[sig & xz <  0 & lagz >  0] <- "Bajo-Alto (LH)"
  list(lisa = lisa, cuadrante = quad, xz = xz, lagz = lagz)
}

calcular_correlograma <- function(x, nb, max_lag = 5) {
  xc <- as.numeric(x); xc[is.na(xc)] <- mean(xc, na.rm = TRUE)
  tryCatch(
    sp.correlogram(nb, xc, order = min(max_lag, 5),
                   method = "I", style = "W", zero.policy = TRUE),
    error = function(e) NULL
  )
}

COL_LISA <- c(
  "Alto-Alto (HH)"   = "#D7191C",
  "Bajo-Bajo (LL)"   = "#2C7BB6",
  "Alto-Bajo (HL)"   = "#FDAE61",
  "Bajo-Alto (LH)"   = "#ABD9E9",
  "No significativo" = "#CCCCCC"
)

# Leaflet helper: renderiza polígonos O puntos con popup y leyenda
mapa_leaflet_var <- function(sf_obj, col_name, titulo_pal = col_name,
                              palette = "YlOrRd", popup_extra = NULL) {
  vals <- as.numeric(sf_obj[[col_name]])
  pal  <- colorNumeric(palette, domain = vals, na.color = "#CCCCCC")
  m    <- leaflet(sf_obj) |> addProviderTiles("CartoDB.Positron")

  popup_txt <- paste0("<b>", titulo_pal, ":</b> ", round(vals, 3))
  if (!is.null(popup_extra)) popup_txt <- paste0(popup_txt, popup_extra)

  if (es_punto_sf(sf_obj)) {
    m <- m |> addCircleMarkers(
      fillColor = ~pal(vals), fillOpacity = 0.85,
      color = "white", weight = 0.8, radius = 5,
      popup = popup_txt)
  } else {
    m <- m |> addPolygons(
      fillColor = ~pal(vals), fillOpacity = 0.75,
      color = "white", weight = 0.6, popup = popup_txt,
      highlightOptions = highlightOptions(weight = 2, color = "#333", bringToFront = TRUE))
  }
  m |> addLegend(pal = pal, values = vals, title = titulo_pal, position = "bottomright")
}

mapa_leaflet_lisa <- function(sf_obj) {
  quad <- sf_obj$Cuadrante
  pal  <- colorFactor(palette = unname(COL_LISA), levels = names(COL_LISA), ordered = FALSE)

  popup_txt <- paste0(
    "<b>Cluster:</b> ", quad,
    "<br><b>LISA I:</b> ", round(sf_obj$LISA_I, 4),
    "<br><b>p-local:</b> ", round(sf_obj$LISA_p, 4)
  )

  m <- leaflet(sf_obj) |> addProviderTiles("CartoDB.Positron")
  if (es_punto_sf(sf_obj)) {
    m <- m |> addCircleMarkers(
      fillColor = ~pal(quad), fillOpacity = 0.9,
      color = "white", weight = 0.8, radius = 6, popup = popup_txt)
  } else {
    m <- m |> addPolygons(
      fillColor = ~pal(quad), fillOpacity = 0.8,
      color = "white", weight = 0.5, popup = popup_txt,
      highlightOptions = highlightOptions(weight = 2, color = "#333", bringToFront = TRUE))
  }
  m |> addLegend(pal = pal, values = ~Cuadrante,
                 title = "Cluster LISA", position = "bottomright")
}

mapa_leaflet_pvalor <- function(sf_obj) {
  sf_obj$sig_cat <- cut(sf_obj$LISA_p,
    breaks = c(-Inf, 0.01, 0.05, 0.10, Inf),
    labels = c("p < 0.01","p < 0.05","p < 0.10","No sig."))
  niveles <- c("p < 0.01","p < 0.05","p < 0.10","No sig.")
  colores_pv <- c("#5E4FA2","#3288BD","#66C2A5","#CCCCCC")
  pal <- colorFactor(palette = colores_pv, levels = niveles)

  m <- leaflet(sf_obj) |> addProviderTiles("CartoDB.Positron")
  if (es_punto_sf(sf_obj)) {
    m <- m |> addCircleMarkers(
      fillColor = ~pal(sig_cat), fillOpacity = 0.85,
      color = "white", weight = 0.8, radius = 5,
      popup = ~paste0("<b>p-valor:</b> ", round(LISA_p, 4),
                      "<br><b>Categoría:</b> ", sig_cat))
  } else {
    m <- m |> addPolygons(
      fillColor = ~pal(sig_cat), fillOpacity = 0.78,
      color = "white", weight = 0.5,
      popup = ~paste0("<b>p-valor:</b> ", round(LISA_p,4),
                      "<br><b>Categoría:</b> ", sig_cat),
      highlightOptions = highlightOptions(weight = 2, bringToFront = TRUE))
  }
  m |> addLegend(pal = pal, values = ~sig_cat,
                 title = "p-valor local", position = "bottomright")
}

# =============================================================================
# UI
# =============================================================================
ui <- dashboardPage(
  skin = "blue",

  dashboardHeader(
    title = tags$span(icon("globe"), " Índice de Moran"),
    titleWidth = 300
  ),

  dashboardSidebar(width = 265,
    sidebarMenu(id = "menu",
      menuItem("Inicio",             tabName = "inicio",      icon = icon("home")),
      menuItem("Moran Global",       tabName = "global",      icon = icon("chart-line")),
      menuItem("Moran Local (LISA)", tabName = "lisa",        icon = icon("map")),
      menuItem("Correlograma",       tabName = "correlogram", icon = icon("wave-square")),
      menuItem("Exploración",        tabName = "explora",     icon = icon("table")),
      menuItem("Reporte",            tabName = "reporte",     icon = icon("file-alt"))
    ),
    hr(),
    tags$div(style = "padding:0 12px;",
      tags$h5(tags$b("Dataset"), style = "color:#cfd8dc; margin-bottom:4px;"),
      selectInput("dataset", NULL, choices = DATASETS, selected = DATASETS[1]),

      tags$h5(tags$b("Variable"), style = "color:#cfd8dc; margin-top:10px; margin-bottom:4px;"),
      selectInput("variable", NULL, choices = NULL),

      tags$h5(tags$b("Matriz de pesos W"), style = "color:#cfd8dc; margin-top:10px; margin-bottom:4px;"),
      selectInput("metodo_w", NULL, choices = METODOS_W),

      conditionalPanel("input.metodo_w == 'knn' || input.metodo_w == 'dist'",
        sliderInput("k_vecinos", "K vecinos:", min = 3, max = 15, value = 5)),

      tags$h5(tags$b("Permutaciones Monte Carlo"),
              style = "color:#cfd8dc; margin-top:10px; margin-bottom:4px;"),
      sliderInput("nsim", NULL, min = 99, max = 2999, value = 999, step = 100),

      tags$h5(tags$b("Nivel α"),
              style = "color:#cfd8dc; margin-top:10px; margin-bottom:4px;"),
      selectInput("alpha", NULL,
        choices = c("0.01"=0.01,"0.05"=0.05,"0.10"=0.10), selected=0.05),

      br(),
      actionBttn("calcular", "▶  Calcular Moran",
        style = "fill", color = "primary", block = TRUE),
      br(),
      uiOutput("badge_estado"),
      br(),
      tags$small(style = "color:#90a4ae;", "sf + spdep + leaflet + plotly")
    )
  ),

  dashboardBody(
    useShinyjs(),
    tags$head(tags$style(HTML("
      .content-wrapper{background:#f4f6f8;}
      .box{border-top:3px solid #1976D2;box-shadow:0 1px 5px rgba(0,0,0,.1);}
      .badge-ok {display:inline-block;padding:5px 12px;border-radius:20px;
                 font-size:13px;font-weight:600;background:#e8f5e9;
                 color:#2e7d32;border:1px solid #a5d6a7;}
      .badge-pend {display:inline-block;padding:5px 12px;border-radius:20px;
                   font-size:13px;font-weight:600;background:#fce4ec;
                   color:#c62828;border:1px solid #ef9a9a;}
    "))),

    tabItems(

      # ── INICIO ──────────────────────────────────────────────────────────────
      tabItem("inicio",
        fluidRow(
          box(width=12, solidHeader=TRUE, status="primary",
            title="¿Qué es el Índice de Moran?",
            fluidRow(
              column(7,
                p("El ", strong("Índice de Moran (I)"), " es la medida clásica de autocorrelación espacial:
                   cuantifica si los valores similares tienden a estar cerca unos de otros en el espacio."),
                tags$ul(
                  tags$li(strong("I ≈ +1:"), " Clustering — valores similares se agrupan"),
                  tags$li(strong("I ≈  0:"), " Aleatoriedad — sin patrón espacial"),
                  tags$li(strong("I ≈ −1:"), " Dispersión — valores disímiles son vecinos")
                ),
                withMathJax(helpText("$$I = \\frac{n}{\\sum_i\\sum_j w_{ij}}
                  \\cdot\\frac{\\sum_i\\sum_j w_{ij}(x_i-\\bar{x})(x_j-\\bar{x})}{\\sum_i(x_i-\\bar{x})^2}$$"))
              ),
              column(5,
                box(width=NULL, background="light-blue",
                  h4("Cómo usar la app", style="margin-top:0"),
                  tags$ol(
                    tags$li("Selecciona un ", strong("dataset")),
                    tags$li("Elige la ", strong("variable")),
                    tags$li("Configura el ", strong("método W")),
                    tags$li("Pulsa ", strong('"Calcular Moran"')),
                    tags$li("Explora las ", strong("6 pestañas"))
                  )
                )
              )
            )
          )
        ),
        fluidRow(
          valueBoxOutput("vbox_dataset", width=3),
          valueBoxOutput("vbox_n",       width=3),
          valueBoxOutput("vbox_vars",    width=3),
          valueBoxOutput("vbox_metodo",  width=3)
        ),
        fluidRow(
          box(width=7, title="Mapa coroplético de la variable", solidHeader=TRUE, status="info",
              leafletOutput("mapa_inicio", height=370)),
          box(width=5, title="Distribución de la variable", solidHeader=TRUE, status="info",
              plotlyOutput("hist_inicio", height=370))
        )
      ),

      # ── MORAN GLOBAL ────────────────────────────────────────────────────────
      tabItem("global",
        fluidRow(
          infoBoxOutput("ibox_I",  width=3),
          infoBoxOutput("ibox_EI", width=3),
          infoBoxOutput("ibox_z",  width=3),
          infoBoxOutput("ibox_p",  width=3)
        ),
        fluidRow(
          box(width=6, solidHeader=TRUE, status="primary",
            title="Diagrama de Dispersión de Moran",
            plotlyOutput("moran_scatter", height=390),
            tags$small(em("Pendiente de la recta = Índice de Moran I. Cuadrantes: HH (arriba-der), LL (abajo-izq), HL/LH (outliers)."))
          ),
          box(width=6, solidHeader=TRUE, status="primary",
            title="Distribución Monte Carlo (permutaciones)",
            plotlyOutput("moran_mc_hist", height=390),
            tags$small(em("Distribución de I bajo H₀ de aleatoriedad. Línea roja = I observado."))
          )
        ),
        fluidRow(
          box(width=12, solidHeader=TRUE, status="warning",
            title="Tabla de estadísticos completa",
            tableOutput("tabla_global"))
        )
      ),

      # ── LISA ────────────────────────────────────────────────────────────────
      tabItem("lisa",
        fluidRow(
          box(width=6, solidHeader=TRUE, status="danger",
            title="Mapa LISA — Clusters espaciales",
            leafletOutput("mapa_lisa", height=420),
            tags$small(em("Rojo=HH (hotspot), Azul=LL (coldspot), Naranja=HL, Celeste=LH, Gris=no sig."))
          ),
          box(width=6, solidHeader=TRUE, status="danger",
            title="Diagrama de dispersión LISA",
            plotlyOutput("lisa_scatter", height=420)
          )
        ),
        fluidRow(
          box(width=6, solidHeader=TRUE, status="info",
            title="Mapa p-valor local",
            leafletOutput("mapa_pvalor", height=330)
          ),
          box(width=6, solidHeader=TRUE, status="info",
            title="Conteo por cuadrante LISA",
            plotlyOutput("lisa_barplot", height=330)
          )
        )
      ),

      # ── CORRELOGRAMA ────────────────────────────────────────────────────────
      tabItem("correlogram",
        fluidRow(
          box(width=8, solidHeader=TRUE, status="success",
            title="Correlograma espacial de Moran",
            plotOutput("correlograma", height=390)
          ),
          box(width=4, solidHeader=TRUE, status="success",
            title="Interpretación",
            uiOutput("interp_corr"))
        ),
        fluidRow(
          box(width=6, title="Red de vecindades (matriz W)", solidHeader=TRUE, status="warning",
              leafletOutput("mapa_vecindades", height=330)),
          box(width=6, title="Estadísticos por orden de lag", solidHeader=TRUE, status="warning",
              DTOutput("tabla_corr"))
        )
      ),

      # ── EXPLORACIÓN ─────────────────────────────────────────────────────────
      tabItem("explora",
        fluidRow(
          box(width=12, solidHeader=TRUE, status="primary",
            title="Mapa interactivo con estadísticos LISA (clic en cada unidad)",
            leafletOutput("mapa_explora", height=430))
        ),
        fluidRow(
          box(width=12, title="Tabla de datos + LISA (filtrable)", solidHeader=TRUE, status="info",
              DTOutput("tabla_datos"))
        )
      ),

      # ── REPORTE ─────────────────────────────────────────────────────────────
      tabItem("reporte",
        fluidRow(
          box(width=12, solidHeader=TRUE, status="success",
            title="Generar reporte automático (HTML / PDF / Word)",
            fluidRow(
              column(4,
                selectInput("fmt_rep", "Formato de salida:",
                  choices=c("HTML"="html","PDF"="pdf","Word"="word")),
                textInput("autor_rep", "Autor:",
                  value="Estudiante de Estadística Espacial"),
                textInput("inst_rep", "Institución:", value="Universidad"),
                br(),
                downloadButton("dl_reporte","Generar y Descargar Reporte",
                               class="btn-success btn-lg")
              ),
              column(8,
                box(width=NULL, background="light-blue",
                  h4("El reporte incluye:", style="margin-top:0"),
                  tags$ul(
                    tags$li("Marco teórico y fórmula del Índice de Moran"),
                    tags$li("Tabla de configuración del análisis"),
                    tags$li("Resultados: I, E[I], Var[I], Z-score, p-valor"),
                    tags$li("Interpretación automática en lenguaje claro"),
                    tags$li("Test de permutación Monte Carlo"),
                    tags$li("Tabla de clusters LISA con porcentajes"),
                    tags$li("Conclusión ejecutiva y recomendaciones"),
                    tags$li("Referencias bibliográficas")
                  )
                )
              )
            )
          )
        )
      )
    )
  )
)

# =============================================================================
# SERVER
# =============================================================================
server <- function(input, output, session) {

  # ── Datos reactivos ──────────────────────────────────────────────────────────
  datos_raw <- reactive({
    tryCatch(cargar_dataset(input$dataset), error = function(e) {
      showNotification(paste("Error:", e$message), type="error", duration=8)
      NULL
    })
  })

  observe({
    d <- datos_raw(); req(d)
    updateSelectInput(session, "variable", choices=d$vars, selected=d$vars[1])
  })

  # ── Análisis principal ───────────────────────────────────────────────────────
  res <- eventReactive(input$calcular, {
    req(input$variable)
    d <- datos_raw(); req(d)

    withProgress(message="Analizando...", value=0, {
      incProgress(0.2, detail="Construyendo W")
      W    <- construir_W(d$sf, input$metodo_w, input$k_vecinos)
      W_nb <- W$neighbours

      incProgress(0.3, detail="Moran Global + Monte Carlo")
      global <- calcular_moran_global(d$sf[[input$variable]], W, input$nsim)

      incProgress(0.3, detail="LISA local")
      local  <- calcular_moran_local(d$sf[[input$variable]], W)

      incProgress(0.1, detail="Correlograma")
      corr   <- calcular_correlograma(d$sf[[input$variable]], W_nb)

      sf_res <- d$sf
      sf_res$LISA_I    <- local$lisa[,1]
      sf_res$LISA_p    <- local$lisa[,5]
      sf_res$Cuadrante <- local$cuadrante
      sf_res$z_score   <- local$xz
      sf_res$lag_z     <- local$lagz
      sf_res$plot_var  <- as.numeric(sf_res[[input$variable]])

      incProgress(0.1, detail="Listo")
    })
    showNotification("✅ Análisis completado", type="message", duration=3)
    list(sf=sf_res, W=W, W_nb=W_nb, global=global, local=local,
         corr=corr, var=input$variable, d=d)
  })

  output$badge_estado <- renderUI({
    if (!is.null(res())) tags$div(class="badge-ok",  "✓ Análisis listo")
    else                  tags$div(class="badge-pend","Pendiente de cálculo")
  })

  # ── Value Boxes ──────────────────────────────────────────────────────────────
  output$vbox_dataset <- renderValueBox({
    valueBox(substr(input$dataset,1,22), "Dataset",
             icon=icon("database"), color="blue")
  })
  output$vbox_n <- renderValueBox({
    d <- datos_raw()
    valueBox(if(!is.null(d)) nrow(d$sf) else "—",
             "Unidades espaciales", icon=icon("map-marker"), color="green")
  })
  output$vbox_vars <- renderValueBox({
    d <- datos_raw()
    valueBox(if(!is.null(d)) length(d$vars) else "—",
             "Variables", icon=icon("columns"), color="yellow")
  })
  output$vbox_metodo <- renderValueBox({
    valueBox(names(METODOS_W)[METODOS_W==input$metodo_w],
             "Método W", icon=icon("project-diagram"), color="purple")
  })

  # ── MAPA INICIO (leaflet) ────────────────────────────────────────────────────
  output$mapa_inicio <- renderLeaflet({
    req(input$variable)
    d <- datos_raw(); req(d)
    sf <- d$sf
    sf$plot_var <- as.numeric(sf[[input$variable]])
    mapa_leaflet_var(sf, "plot_var", titulo_pal = input$variable)
  })

  output$hist_inicio <- renderPlotly({
    req(input$variable)
    d <- datos_raw(); req(d)
    x <- as.numeric(d$sf[[input$variable]]); x <- x[!is.na(x)]
    plot_ly(x=x, type="histogram",
            marker=list(color="#378ADD", line=list(color="white",width=0.5))) |>
      layout(xaxis=list(title=input$variable), yaxis=list(title="Frecuencia"),
             title=paste("Distribución de", input$variable))
  })

  # ── Info Boxes Moran Global ──────────────────────────────────────────────────
  output$ibox_I <- renderInfoBox({
    req(res()); I <- round(res()$global$I, 4)
    infoBox("Moran I", I, icon=icon("chart-line"),
            color=ifelse(I>0,"blue","red"), fill=TRUE)
  })
  output$ibox_EI <- renderInfoBox({
    req(res()); EI <- round(res()$global$EI, 4)
    infoBox("E[I] esperado", EI, icon=icon("minus"), color="yellow", fill=TRUE)
  })
  output$ibox_z <- renderInfoBox({
    req(res()); z <- round(res()$global$z_score, 3)
    infoBox("Z-score", z, icon=icon("tachometer-alt"),
            color=ifelse(abs(z)>1.96,"green","orange"), fill=TRUE)
  })
  output$ibox_p <- renderInfoBox({
    req(res())
    p <- res()$global$p_value; pm <- res()$global$p_mc
    alpha <- as.numeric(input$alpha); sig <- p < alpha
    infoBox(paste("p-valor", ifelse(sig,"(SIG.)","(no sig.)")),
      paste0("analít: ",round(p,4)," | MC: ",round(pm,4)),
      icon=icon(ifelse(sig,"check-circle","times-circle")),
      color=ifelse(sig,"green","red"), fill=TRUE)
  })

  # ── Diagrama de dispersión de Moran ─────────────────────────────────────────
  output$moran_scatter <- renderPlotly({
    req(res())
    sf <- res()$sf; I <- round(res()$global$I, 4)
    df <- data.frame(z=sf$z_score, lag=sf$lag_z, v=sf$plot_var)
    fit <- lm(lag ~ z, data=df)
    plot_ly(df, x=~z, y=~lag, type="scatter", mode="markers",
            marker=list(color="#4C93C4", size=7, opacity=0.7),
            text=~paste0("z: ",round(z,3),"<br>lag: ",round(lag,3)),
            hoverinfo="text") |>
      add_lines(x=sort(df$z), y=fitted(fit)[order(df$z)],
                line=list(color="#E24B4A",width=2.5),
                name=paste0("I = ",I), showlegend=TRUE) |>
      add_lines(x=range(df$z), y=c(0,0),
                line=list(color="gray60",dash="dash"), showlegend=FALSE) |>
      add_lines(x=c(0,0), y=range(df$lag),
                line=list(color="gray60",dash="dash"), showlegend=FALSE) |>
      layout(xaxis=list(title="Variable estandarizada (z)"),
             yaxis=list(title="Retardo espacial (lag-z)"),
             title=paste("Diagrama de Moran  —  I =", I),
             annotations=list(
               list(x=max(df$z)*0.7, y=max(df$lag)*0.85, text="HH",
                    showarrow=FALSE, font=list(color="#D7191C",size=13)),
               list(x=min(df$z)*0.7, y=min(df$lag)*0.85, text="LL",
                    showarrow=FALSE, font=list(color="#2C7BB6",size=13)),
               list(x=max(df$z)*0.7, y=min(df$lag)*0.85, text="HL",
                    showarrow=FALSE, font=list(color="#FDAE61",size=13)),
               list(x=min(df$z)*0.7, y=max(df$lag)*0.85, text="LH",
                    showarrow=FALSE, font=list(color="#ABD9E9",size=13))
             ))
  })

  # ── Histograma Monte Carlo ───────────────────────────────────────────────────
  output$moran_mc_hist <- renderPlotly({
    req(res())
    sims <- as.numeric(res()$global$mc$res)
    I    <- res()$global$I; p <- round(res()$global$p_mc, 4)
    plot_ly(x=sims, type="histogram",
            marker=list(color="#9FE1CB", line=list(color="white",width=0.3)),
            name="Simulaciones") |>
      add_lines(x=c(I,I), y=c(0, length(sims)/5),
                line=list(color="#E24B4A",width=3),
                name=paste0("I obs = ",round(I,4))) |>
      layout(xaxis=list(title="Moran I simulado"),
             yaxis=list(title="Frecuencia"),
             title=paste0("Monte Carlo (",length(sims)," permut.)  p-MC = ",p))
  })

  # ── Tabla global ─────────────────────────────────────────────────────────────
  output$tabla_global <- renderTable({
    req(res())
    g <- res()$global; alpha <- as.numeric(input$alpha); sig <- g$p_value < alpha
    data.frame(
      Estadístico = c("Índice de Moran (I)","Esperanza E[I]","Varianza Var[I]",
                      "Z-score","p-valor asintótico","p-valor Monte Carlo",
                      "Permutaciones",paste0("Significativo (α=",alpha,")"),"Interpretación"),
      Valor = c(round(g$I,6), round(g$EI,6), round(g$VarI,8), round(g$z_score,4),
                format.pval(g$p_value,digits=4), format.pval(g$p_mc,digits=4),
                as.character(input$nsim),
                ifelse(sig,"SÍ — se rechaza H₀","NO — no se rechaza H₀"),
                ifelse(g$I>0&sig,"Autocorrelación POSITIVA (clustering)",
                  ifelse(g$I<0&sig,"Autocorrelación NEGATIVA (dispersión)",
                         "Sin autocorrelación significativa"))),
      stringsAsFactors=FALSE)
  }, striped=TRUE, hover=TRUE, bordered=TRUE)

  # ── LISA: mapa, scatter, p-valor, barplot ────────────────────────────────────
  output$mapa_lisa <- renderLeaflet({
    req(res()); mapa_leaflet_lisa(res()$sf)
  })

  output$mapa_pvalor <- renderLeaflet({
    req(res()); mapa_leaflet_pvalor(res()$sf)
  })

  output$lisa_scatter <- renderPlotly({
    req(res())
    sf  <- res()$sf
    df  <- as.data.frame(sf)
    cols <- COL_LISA[as.character(df$Cuadrante)]
    plot_ly(df, x=~z_score, y=~lag_z, type="scatter", mode="markers",
            marker=list(color=cols, size=8, opacity=0.85),
            text=~paste0("Cuadrante: ",Cuadrante,
                         "<br>z: ",round(z_score,3),
                         "<br>lag: ",round(lag_z,3),
                         "<br>p-local: ",round(LISA_p,4)),
            hoverinfo="text") |>
      add_lines(x=range(df$z_score), y=c(0,0),
                line=list(color="gray60",dash="dash"), showlegend=FALSE) |>
      add_lines(x=c(0,0), y=range(df$lag_z),
                line=list(color="gray60",dash="dash"), showlegend=FALSE) |>
      layout(xaxis=list(title="z-score"),
             yaxis=list(title="Retardo espacial (lag-z)"),
             title="Cuadrantes LISA",
             annotations=list(
               list(x=max(df$z_score)*0.7, y=max(df$lag_z)*0.85, text="HH",
                    showarrow=FALSE, font=list(color="#D7191C",size=13)),
               list(x=min(df$z_score)*0.7, y=min(df$lag_z)*0.85, text="LL",
                    showarrow=FALSE, font=list(color="#2C7BB6",size=13)),
               list(x=max(df$z_score)*0.7, y=min(df$lag_z)*0.85, text="HL",
                    showarrow=FALSE, font=list(color="#FDAE61",size=13)),
               list(x=min(df$z_score)*0.7, y=max(df$lag_z)*0.85, text="LH",
                    showarrow=FALSE, font=list(color="#ABD9E9",size=13))
             ))
  })

  output$lisa_barplot <- renderPlotly({
    req(res())
    df <- as.data.frame(table(res()$sf$Cuadrante))
    names(df) <- c("Cuadrante","N")
    df <- df[order(df$N, decreasing=TRUE),]
    plot_ly(df, x=~Cuadrante, y=~N, type="bar",
            marker=list(color=COL_LISA[as.character(df$Cuadrante)])) |>
      layout(xaxis=list(title=""), yaxis=list(title="Unidades"),
             title="Distribución de clusters LISA")
  })

  # ── Correlograma ─────────────────────────────────────────────────────────────
  output$correlograma <- renderPlot({
    req(res())
    corr <- res()$corr
    if (is.null(corr)) {
      plot.new(); text(0.5,0.5,"Correlograma no disponible",cex=1.2,col="gray50")
      return()
    }
    plot(corr, main=paste("Correlograma de Moran —", res()$var),
         xlab="Orden de vecindad (lag)", ylab="Moran I",
         col="#185FA5", lwd=2, pch=19, cex=1.4)
    abline(h=0, lty=2, col="gray50"); grid(col="gray90")
  }, bg="white")

  output$interp_corr <- renderUI({
    req(res())
    g <- res()$global; I <- g$I; p <- g$p_value
    tags$div(
      h5("Estadísticos globales"),
      p(paste("I =", round(I,4))),
      p(paste("p =", format.pval(p, digits=3))),
      hr(),
      h5("Lectura del gráfico"),
      tags$ul(
        tags$li("Cada punto = I calculado para ese orden de lag"),
        tags$li("I decrece rápido → autocorrelación local"),
        tags$li("I se mantiene alto → autocorrelación global"),
        tags$li("Barras de error = IC al 95%")
      ), hr(),
      if (I > 0.3 & p < 0.05)
        tags$div(class="badge-ok", "Clustering fuerte detectado")
      else if (I > 0 & p < 0.05)
        tags$div(class="badge-ok", "Clustering moderado detectado")
      else
        tags$div(class="badge-pend", "Sin autocorrelación significativa")
    )
  })

  output$tabla_corr <- renderDT({
    req(res()); corr <- res()$corr
    if (is.null(corr)) return(datatable(data.frame(Info="No disponible")))
    df <- tryCatch(round(as.data.frame(print(corr)),5), error=function(e) NULL)
    if (is.null(df)) return(datatable(data.frame(Info="Error")))
    datatable(df, options=list(pageLength=8, dom="t"),
              rownames=TRUE, class="compact stripe")
  })

  output$mapa_vecindades <- renderLeaflet({
    req(res())
    sf   <- res()$sf; W_nb <- res()$W_nb
    coords <- st_coordinates(st_centroid(st_geometry(sf)))
    m <- leaflet() |> addProviderTiles("CartoDB.Positron")
    if (!es_punto_sf(sf))
      m <- m |> addPolygons(data=sf, fillColor="#B5D4F4", fillOpacity=0.2,
                             color="#185FA5", weight=0.7)
    for (i in seq_along(W_nb)) for (j in W_nb[[i]])
      m <- m |> addPolylines(lng=c(coords[i,1],coords[j,1]),
                              lat=c(coords[i,2],coords[j,2]),
                              color="#E24B4A", weight=0.5, opacity=0.35)
    m |> addCircleMarkers(lng=coords[,1], lat=coords[,2],
                          radius=3, color="#E24B4A", fillOpacity=0.9, stroke=FALSE)
  })

  # ── Exploración ──────────────────────────────────────────────────────────────
  output$mapa_explora <- renderLeaflet({
    req(res())
    sf  <- res()$sf; var <- res()$var
    extra <- paste0("<br><b>Cluster LISA:</b> ", sf$Cuadrante,
                    "<br><b>LISA I:</b> ", round(sf$LISA_I,4),
                    "<br><b>p-local:</b> ", round(sf$LISA_p,4))
    mapa_leaflet_var(sf, "plot_var", titulo_pal=var, popup_extra=extra)
  })

  output$tabla_datos <- renderDT({
    req(res())
    sf  <- res()$sf; var <- res()$var
    df  <- as.data.frame(sf) |>
      select(any_of(c("NAME","name","COUNTY","NAME_1","name_long",names(sf)[1])),
             all_of(var), z_score, lag_z, LISA_I, LISA_p, Cuadrante) |>
      mutate(across(where(is.numeric), ~round(.,4)))
    datatable(df, filter="top", rownames=FALSE,
              options=list(pageLength=15, scrollX=TRUE),
              class="compact stripe hover") |>
      formatStyle("Cuadrante",
        backgroundColor=styleEqual(names(COL_LISA), unname(COL_LISA)),
        color="white")
  })

  # ── REPORTE RMarkdown ─────────────────────────────────────────────────────────
  output$dl_reporte <- downloadHandler(
    filename = function() {
      ext <- switch(input$fmt_rep, html=".html", pdf=".pdf", word=".docx")
      paste0("reporte_moran_", gsub("[^A-Za-z0-9]","_",input$dataset),
             "_", Sys.Date(), ext)
    },
    content = function(file) {
      req(res())
      r <- res(); g <- r$global; sf <- r$sf

      tabla_res <- data.frame(
        Cuadrante = names(table(sf$Cuadrante)),
        N         = as.integer(table(sf$Cuadrante)),
        Pct       = round(100*as.numeric(table(sf$Cuadrante))/nrow(sf), 1),
        stringsAsFactors = FALSE
      )

      params <- list(
        dataset = input$dataset, variable = r$var,
        titulo  = r$d$titulo,   desc     = r$d$desc,
        n       = nrow(sf),     metodo_w = input$metodo_w,
        nsim    = input$nsim,   alpha    = as.numeric(input$alpha),
        moran_I = round(g$I,6), moran_EI = round(g$EI,6),
        moran_VarI  = round(g$VarI,8), z_score = round(g$z_score,4),
        p_value = g$p_value,    p_mc     = g$p_mc,
        sig     = g$p_value < as.numeric(input$alpha),
        autor   = input$autor_rep, institucion = input$inst_rep,
        tabla_resumen = tabla_res
      )

      rmd_tmp <- file.path(tempdir(), "reporte_moran.Rmd")
      file.copy("reporte_moran.Rmd", rmd_tmp, overwrite=TRUE)

      fmt <- switch(input$fmt_rep,
        html = rmarkdown::html_document(toc=TRUE, theme="flatly", highlight="tango"),
        pdf  = rmarkdown::pdf_document(toc=TRUE),
        word = rmarkdown::word_document(toc=TRUE))

      tryCatch(
        rmarkdown::render(input=rmd_tmp, output_format=fmt, output_file=file,
                          params=params, envir=new.env(parent=globalenv()), quiet=TRUE),
        error = function(e)
          showNotification(paste("Error reporte:", e$message), type="error", duration=10)
      )
    }
  )
}

shinyApp(ui=ui, server=server)
