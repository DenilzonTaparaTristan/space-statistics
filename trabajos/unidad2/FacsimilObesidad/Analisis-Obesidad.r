##################################################################################
# Estructura:
#   PARTE 0 -- Configuración y librerías
#   PARTE 1 -- Carga de módulos (.sav), con verificación previa de archivos
#   PARTE 2 -- Limpieza y construcción de variables (CORREGIDA)
#   PARTE 3 -- Análisis descriptivo (Tabla 1, Tabla 2, prevalencia estandarizada)
#   PARTE 4 -- Análisis espacial A NIVEL CONGLOMERADO
#   PARTE 5 -- Análisis espacial A NIVEL DISTRITAL
#   PARTE 6 -- Figura 1 combinada (A+B+C+D) al estilo del paper
#
# Requiere en D:/datos/datos:
#   RECH0.sav, RECH1.sav, RECH23.sav, REC0111.sav, CSALUD01.sav
#   DEPARTAMENTOS.shp / DISTRITOS.shp (opcionales; si faltan, se descargan)
# =============================================================================

# =============================================================================
# PARTE 0. CONFIGURACIÓN Y LIBRERÍAS
# =============================================================================

paquetes_necesarios <- c(
  "haven", "dplyr", "tidyr", "stringr", "janitor",
  "survey", "srvyr", "gtsummary", "gt",
  "sf", "spdep", "ggplot2",
  "ggspatial", "patchwork"
)
paquetes_faltantes <- setdiff(paquetes_necesarios, rownames(installed.packages()))
if (length(paquetes_faltantes) > 0) install.packages(paquetes_faltantes)

library(haven); library(dplyr); library(tidyr); library(stringr); library(janitor)
library(survey); library(srvyr); library(gtsummary); library(gt)
library(sf); library(spdep); library(ggplot2); library(ggspatial); library(patchwork)

options(survey.lonely.psu = "adjust")

ruta_raw <- "D:/datos/datos"   # <-- AJUSTA si cambia

dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)
dir.create("output",         recursive = TRUE, showWarnings = FALSE)

paleta_lisa <- c(
  "Alto-Alto"            = "#E31A1C",
  "Bajo-Bajo"             = "#33A02C",
  "Alto-Bajo (atípico)"   = "#FF7F00",
  "Bajo-Alto (atípico)"   = "#B2DF8A",
  "No significativo"      = "#F0F0F0"
)
paleta_gi <- c(
  "Punto caliente - 99% confianza" = "#B2182B",
  "Punto caliente - 95% confianza" = "#D6604D",
  "Punto caliente - 90% confianza" = "#F4A582",
  "No significativo"               = "#FFFFBF",
  "Punto frío - 90% confianza"     = "#92C5DE",
  "Punto frío - 95% confianza"     = "#4393C3",
  "Punto frío - 99% confianza"     = "#2166AC"
)

tema_mapa_paper <- function() {
  theme_minimal(base_size = 11) +
    theme(
      plot.title    = element_text(face = "bold", size = 16, hjust = 0),
      plot.subtitle = element_text(size = 10, color = "grey30", hjust = 0),
      legend.position = c(0.18, 0.15),
      legend.background = element_rect(fill = "white", color = "black", linewidth = 0.5),
      legend.title  = element_text(size = 9, face = "bold"),
      legend.text   = element_text(size = 8),
      legend.margin = margin(t = 4, r = 6, b = 4, l = 6),
      plot.caption  = element_text(size = 7, color = "grey50", hjust = 0),
      panel.background = element_rect(fill = "#e0f3f8", color = "black", linewidth = 1),
      plot.background  = element_rect(fill = "white", color = NA),
      panel.grid.major = element_line(color = "grey60", linetype = "dashed", linewidth = 0.3),
      panel.grid.minor = element_blank(),
      axis.text = element_text(size = 8, color = "black"),
      axis.title = element_blank()
    )
}

capa_norte_escala <- function() {
  list(
    annotation_scale(location = "bl", width_hint = 0.25, text_cex = 0.6),
    annotation_north_arrow(location = "tr", which_north = "true",
                           style = north_arrow_fancy_orienteering(),
                           height = unit(1, "cm"), width = unit(1, "cm"))
  )
}


# =============================================================================
# PARTE 1. CARGA DE MÓDULOS (.sav)
# =============================================================================

cat("\n=====================================================\n")
cat("PARTE 1: Cargando módulos ENDES 2022 desde", ruta_raw, "\n")
cat("=====================================================\n")

if (!dir.exists(ruta_raw)) stop("La carpeta '", ruta_raw, "' no existe.")

archivos_requeridos <- c("CSALUD01.sav", "RECH0.sav", "RECH1.sav", "RECH23.sav", "REC0111.sav")
archivos_en_carpeta <- list.files(ruta_raw, recursive = TRUE)

for (arch in archivos_requeridos) {
  existe <- any(grepl(paste0("^", arch, "$"), basename(archivos_en_carpeta), ignore.case = TRUE))
  if (!existe) stop("No se encontró '", arch, "' dentro de '", ruta_raw, "'.")
}
cat("Los 5 archivos .sav requeridos fueron encontrados. Cargando...\n")

ruta_archivo <- function(nombre) {
  encontrado <- archivos_en_carpeta[grepl(paste0("^", nombre, "$"),
                                          basename(archivos_en_carpeta),
                                          ignore.case = TRUE)][1]
  file.path(ruta_raw, encontrado)
}

csalud01 <- read_sav(ruta_archivo("CSALUD01.sav"))
rech0    <- read_sav(ruta_archivo("RECH0.sav"))
rech23   <- read_sav(ruta_archivo("RECH23.sav"))

rech0    <- janitor::clean_names(rech0)
rech23   <- janitor::clean_names(rech23)
csalud01 <- janitor::clean_names(csalud01)

saveRDS(rech0,    "data/processed/rech0.rds")
saveRDS(rech23,   "data/processed/rech23.rds")
saveRDS(csalud01, "data/processed/csalud01.rds")

cat("Filas -> RECH0:", nrow(rech0), "| RECH23:", nrow(rech23),
    "| CSALUD01:", nrow(csalud01), "\n")

candidatos_ponderador <- grep("peso.*amas|amas.*peso", names(csalud01),
                              ignore.case = TRUE, value = TRUE)
if (length(candidatos_ponderador) == 0) stop("No se encontró el ponderador 'peso15_amas'.")
nombre_ponderador <- candidatos_ponderador[1]
cat("Ponderador detectado:", nombre_ponderador, "\n")


# =============================================================================
# PARTE 2. LIMPIEZA Y CONSTRUCCIÓN DE VARIABLES (CORREGIDA)
# =============================================================================

cat("\n=====================================================\n")
cat("PARTE 2: Construyendo variables (obesidad como desenlace principal)\n")
cat("=====================================================\n")

csalud01_ob <- csalud01 %>%
  mutate(
    peso_kg = as.numeric(qs900),
    talla_m = as.numeric(qs901) / 100,
    imc     = peso_kg / (talla_m^2),
    # BUG #1 CORREGIDO: ya NO se filtra por qs902 (resultado antropometría).
    # Ese código indica CÓMO se obtuvo el dato (ej. "4 = evaluada en
    # Cuestionario del Hogar", común en mujeres), no si es válido. Filtrar
    # por qs902==1 sesgaba la muestra hacia hombres (73% vs 47,9% esperado).
    imc     = if_else(imc < 12 | imc > 60, NA_real_, imc),
    estado_nutricional = case_when(
      imc < 18.5 ~ "Bajo peso",
      imc >= 18.5 & imc < 25 ~ "Hasta normal",
      imc >= 25  & imc < 30 ~ "Sobrepeso",
      imc >= 30 ~ "Obesidad",
      TRUE ~ NA_character_
    ),
    obesidad = case_when(
      imc >= 30 ~ 1,
      imc <  30 & !is.na(imc) ~ 0,
      TRUE ~ NA_real_
    ),
    obesidad_lab = factor(obesidad, levels = c(0, 1), labels = c("No obeso", "Obeso"))
  )

csalud01_ob <- csalud01_ob %>%
  mutate(
    diabetes_dx = case_when(qs109 == 1 ~ "Sí", qs109 == 2 ~ "No", TRUE ~ NA_character_),
    
    # BUG #2 y #3 CORREGIDOS: fumador/bebedor "actual" = últimos 30 días,
    # con cascada por los filtros previos del cuestionario para que los
    # abstemios/no-fumadores queden como "No" y no como NA.
    fumador = case_when(
      qs201 == 1 ~ "Sí",
      qs201 == 2 ~ "No",
      qs200 == 2 ~ "No",
      TRUE ~ NA_character_
    ),
    bebedor = case_when(
      qs210 == 1 ~ "Sí",
      qs210 == 2 ~ "No",
      qs208 == 2 ~ "No",
      qs206 == 2 ~ "No",
      TRUE ~ NA_character_
    )
  )

csalud01_ob <- csalud01_ob %>%
  mutate(
    pas_1 = as.numeric(qs903s), pad_1 = as.numeric(qs903d),
    pas_2 = as.numeric(qs905s), pad_2 = as.numeric(qs905d),
    pas_prom = rowMeans(cbind(pas_1, pas_2), na.rm = TRUE),
    pad_prom = rowMeans(cbind(pad_1, pad_2), na.rm = TRUE),
    hta = if_else(pas_prom >= 140 | pad_prom >= 90, 1, 0),
    hta_lab = factor(hta, levels = c(0, 1), labels = c("No", "Sí"))
  )

csalud01_ob <- csalud01_ob %>%
  mutate(
    sexo = case_when(qssexo == 1 ~ "Hombre", qssexo == 2 ~ "Mujer", TRUE ~ NA_character_),
    edad = as.numeric(qs23),
    grupo_etario = case_when(
      edad >= 18 & edad <= 29 ~ "18-29 años",
      edad >= 30 & edad <= 59 ~ "30-59 años",
      edad >= 60 ~ "60 o más años",
      TRUE ~ NA_character_
    ),
    peso_muestral = as.numeric(.data[[nombre_ponderador]]) / 1000000,
    conglomerado  = as.numeric(qhcluster)
  )

# --- Unir con RECH0: estrato, área, región, ubigeo Y COORDENADAS GPS
#     (necesarias para la Parte 4, análisis espacial a nivel conglomerado) ---
rech0_sel <- rech0 %>%
  select(hhid, hv022, hv024, hv025, ubigeo, longitudx, latitudy) %>%
  distinct(hhid, .keep_all = TRUE)

base <- csalud01_ob %>% left_join(rech0_sel, by = "hhid")

cat("\nFilas en 'base' tras el left_join con RECH0:", nrow(base), "\n")
cat("NA en hv022 (hogares sin match):", sum(is.na(base$hv022)), "\n")

rech23_riqueza <- rech23 %>% select(hhid, hv270) %>% distinct(hhid, .keep_all = TRUE)
base <- base %>%
  left_join(rech23_riqueza, by = "hhid") %>%
  mutate(quintil_riqueza = factor(hv270, levels = 1:5,
                                  labels = c("Más pobre", "Pobre", "Medio", "Rico", "Más rico")))

base <- base %>%
  mutate(
    area = case_when(hv025 == 1 ~ "Urbana", hv025 == 2 ~ "Rural", TRUE ~ NA_character_),
    estrato = hv022,
    ubigeo6 = str_pad(as.character(ubigeo), width = 6, side = "left", pad = "0"),
    ubigeo_prov = str_sub(ubigeo6, 3, 4),
    region_natural = case_when(
      hv024 == 15 & ubigeo_prov == "01" ~ "Lima Metropolitana",
      hv024 == 7  ~ "Lima Metropolitana",
      hv024 %in% c(24, 20, 14, 13, 2, 15, 11, 4, 18, 23) ~ "Resto de costa",
      hv024 %in% c(6, 1, 9, 5, 3, 8, 21, 12, 19, 10) ~ "Sierra",
      hv024 %in% c(16, 17, 22, 25) ~ "Selva",
      TRUE ~ NA_character_
    )
  ) %>%
  filter(
    edad >= 18,
    !is.na(obesidad),
    !is.na(peso_muestral),
    !is.na(estrato),
    !is.na(conglomerado)
  )

cat("\nMuestra final:", nrow(base), "adultos con medición válida de IMC\n")
if (nrow(base) == 0) stop("La base final quedó con 0 filas. Revisa el left_join con RECH0.")

cat("\nVerificación rápida (deberían parecerse a Paper 1):\n")
print(prop.table(table(base$sexo, useNA = "ifany")))
print(prop.table(table(base$fumador, useNA = "ifany")))
print(prop.table(table(base$bebedor, useNA = "ifany")))

saveRDS(base, "data/processed/base_analitica_obesidad.rds")


# =============================================================================
# PARTE 3. ANÁLISIS DESCRIPTIVO
# =============================================================================

cat("\n=====================================================\n")
cat("PARTE 3: Análisis descriptivo\n")
cat("=====================================================\n")

diseno <- base %>%
  as_survey_design(ids = conglomerado, strata = estrato, weights = peso_muestral, nest = TRUE)

tabla1 <- diseno %>%
  tbl_svysummary(
    include = c(sexo, grupo_etario, area, quintil_riqueza, region_natural,
                diabetes_dx, fumador, bebedor, hta_lab),
    statistic = list(all_categorical() ~ "{n} ({p}%)")
  ) %>%
  bold_labels()
print(tabla1)
gtsummary::as_gt(tabla1) |> gt::gtsave("output/tabla1_caracteristicas_obesidad.html")

prev_cruda <- svymean(~obesidad, diseno, na.rm = TRUE)
cat("\nPrevalencia CRUDA de obesidad:\n"); print(prev_cruda); print(confint(prev_cruda))

pesos_oms_completos <- c(
  "15-19" = 8.47, "20-24" = 8.22, "25-29" = 7.93, "30-34" = 7.61,
  "35-39" = 7.15, "40-44" = 6.59, "45-49" = 6.04, "50-54" = 5.37,
  "55-59" = 4.55, "60-64" = 3.72, "65-69" = 2.96, "70-74" = 2.21,
  "75-79" = 1.52, "80+"   = 0.91 + 0.63
)
pesos_oms_norm <- pesos_oms_completos / sum(pesos_oms_completos)

base <- base %>%
  mutate(grupo_quinquenal = case_when(
    edad >= 18 & edad <= 19 ~ "15-19", edad >= 20 & edad <= 24 ~ "20-24",
    edad >= 25 & edad <= 29 ~ "25-29", edad >= 30 & edad <= 34 ~ "30-34",
    edad >= 35 & edad <= 39 ~ "35-39", edad >= 40 & edad <= 44 ~ "40-44",
    edad >= 45 & edad <= 49 ~ "45-49", edad >= 50 & edad <= 54 ~ "50-54",
    edad >= 55 & edad <= 59 ~ "55-59", edad >= 60 & edad <= 64 ~ "60-64",
    edad >= 65 & edad <= 69 ~ "65-69", edad >= 70 & edad <= 74 ~ "70-74",
    edad >= 75 & edad <= 79 ~ "75-79", edad >= 80 ~ "80+", TRUE ~ NA_character_
  ))

diseno_edad <- base %>%
  as_survey_design(ids = conglomerado, strata = estrato, weights = peso_muestral, nest = TRUE)
prev_por_quinquenio <- svyby(~obesidad, ~grupo_quinquenal, diseno_edad, svymean, na.rm = TRUE)
pesos_usados <- pesos_oms_norm[prev_por_quinquenio$grupo_quinquenal]
pesos_usados <- pesos_usados / sum(pesos_usados)
prev_estandarizada <- sum(prev_por_quinquenio$obesidad * pesos_usados)
cat("\nPrevalencia ESTANDARIZADA por edad de obesidad:",
    round(prev_estandarizada * 100, 1), "%\n")

diseno <- base %>%
  as_survey_design(ids = conglomerado, strata = estrato, weights = peso_muestral, nest = TRUE)

tabla2 <- diseno %>%
  tbl_svysummary(
    by = obesidad_lab,
    include = c(sexo, grupo_etario, area, quintil_riqueza, region_natural,
                diabetes_dx, fumador, bebedor, hta_lab),
    statistic = list(all_categorical() ~ "{p}%"),
    percent = "row"
  ) %>%
  add_ci() %>%
  add_p(test = everything() ~ "svy.chisq.test") %>%
  bold_labels()
print(tabla2)
gtsummary::as_gt(tabla2) |> gt::gtsave("output/tabla2_prevalencia_obesidad.html")


# =============================================================================
# PARTE 4. ANÁLISIS ESPACIAL A NIVEL DE CONGLOMERADO
# =============================================================================

cat("\n=====================================================\n")
cat("PARTE 4: Análisis espacial -- nivel conglomerado\n")
cat("=====================================================\n")

prev_conglomerado <- base %>%
  filter(!is.na(longitudx), !is.na(latitudy), longitudx != 0, latitudy != 0) %>%
  group_by(conglomerado, longitudx, latitudy) %>%
  summarise(
    n_encuestados = n(),
    prev_obesidad = weighted.mean(obesidad, w = peso_muestral, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  filter(n_encuestados >= 3)

cat("Conglomerados con coordenadas válidas y n>=3:", nrow(prev_conglomerado), "\n")
if (nrow(prev_conglomerado) < 10) stop("Muy pocos conglomerados tienen coordenadas GPS válidas.")

puntos_sf <- st_as_sf(prev_conglomerado, coords = c("longitudx", "latitudy"), crs = 4326)

coords <- st_coordinates(puntos_sf)
vecinos_nb <- knn2nb(knearneigh(coords, k = 8))
pesos_w    <- nb2listw(vecinos_nb, style = "W")

moran_global <- moran.test(puntos_sf$prev_obesidad, pesos_w)
cat("\n--- Índice global de Moran (obesidad, conglomerado) ---\n")
print(moran_global)

moran_I <- unname(moran_global$estimate["Moran I statistic"])
moran_z <- unname(moran_global$statistic)
moran_p <- moran_global$p.value
cat("\nPara copiar al texto del artículo:\n  ",
    sprintf("índice global de Moran %.6f, %s y z-score %.2f", moran_I,
            ifelse(moran_p < 0.001, "p < 0,001", paste0("p = ", round(moran_p, 3))),
            moran_z), "\n")

png("output/moran_scatterplot_conglomerado.png", width = 1600, height = 1600, res = 220)
moran.plot(puntos_sf$prev_obesidad, pesos_w,
           xlab = "Prevalencia de obesidad (conglomerado)",
           ylab = "Rezago espacial (promedio de vecinos)",
           pch = 20, col = "#2c3e50", cex = 0.8,
           main = "Diagrama de dispersión de Moran -- obesidad (conglomerado)")
dev.off()

lisa <- localmoran(puntos_sf$prev_obesidad, pesos_w)
puntos_sf <- puntos_sf %>%
  mutate(
    lisa_p   = lisa[, "Pr(z != E(Ii))"],
    prev_z   = as.numeric(scale(prev_obesidad)),
    prev_lag = lag.listw(pesos_w, prev_obesidad),
    lag_z    = as.numeric(scale(prev_lag)),
    cluster_lisa = case_when(
      lisa_p >= 0.05 ~ "No significativo",
      prev_z > 0 & lag_z > 0 ~ "Alto-Alto",
      prev_z < 0 & lag_z < 0 ~ "Bajo-Bajo",
      prev_z > 0 & lag_z < 0 ~ "Alto-Bajo (atípico)",
      prev_z < 0 & lag_z > 0 ~ "Bajo-Alto (atípico)",
      TRUE ~ "No significativo"
    ),
    cluster_lisa = factor(cluster_lisa, levels = names(paleta_lisa))
  )

pesos_gi <- nb2listw(include.self(vecinos_nb), style = "B")
gi_star  <- localG(puntos_sf$prev_obesidad, pesos_gi)
puntos_sf <- puntos_sf %>%
  mutate(
    gi_z = as.numeric(gi_star),
    hotspot = case_when(
      gi_z >=  2.58 ~ "Punto caliente - 99% confianza",
      gi_z >=  1.96 ~ "Punto caliente - 95% confianza",
      gi_z >=  1.65 ~ "Punto caliente - 90% confianza",
      gi_z <= -2.58 ~ "Punto frío - 99% confianza",
      gi_z <= -1.96 ~ "Punto frío - 95% confianza",
      gi_z <= -1.65 ~ "Punto frío - 90% confianza",
      TRUE ~ "No significativo"
    ),
    hotspot = factor(hotspot, levels = names(paleta_gi))
  )

ruta_deptos <- file.path(ruta_raw, "DEPARTAMENTOS.shp")
url_deptos <- "https://raw.githubusercontent.com/juaneladio/peru-geojson/master/peru_departamental_simple.geojson"

peru_departamentos <- tryCatch({
  if (file.exists(ruta_deptos)) {
    st_read(ruta_deptos, quiet = TRUE)
  } else {
    cat("\nDescargando mapa departamental desde repositorio web...\n")
    st_read(url_deptos, quiet = TRUE)
  }
}, error = function(e) NULL)

if (is.null(peru_departamentos)) {
  cat("\nAVISO: no se pudo cargar el mapa departamental base. Los mapas irán sin contorno.\n")
}

mapa_A_lisa_congl <- ggplot() +
  { if (!is.null(peru_departamentos))
    geom_sf(data = peru_departamentos, fill = "white", color = "black", linewidth = 0.4) } +
  geom_sf(data = puntos_sf, aes(fill = cluster_lisa), shape = 21, color = "black", size = 2.5, alpha = 0.9) +
  scale_fill_manual(values = paleta_lisa, drop = FALSE, name = "Leyenda") +
  labs(title = "A") +
  guides(fill = guide_legend(override.aes = list(size = 4))) +
  capa_norte_escala() +
  tema_mapa_paper()

mapa_B_gi_congl <- ggplot() +
  { if (!is.null(peru_departamentos))
    geom_sf(data = peru_departamentos, fill = "white", color = "black", linewidth = 0.4) } +
  geom_sf(data = puntos_sf, aes(fill = hotspot), shape = 21, color = "black", size = 2.5, alpha = 0.9) +
  scale_fill_manual(values = paleta_gi, drop = FALSE, name = "Leyenda") +
  labs(title = "B") +
  guides(fill = guide_legend(override.aes = list(size = 4))) +
  capa_norte_escala() +
  tema_mapa_paper()

ggsave("output/mapaA_lisa_conglomerado_obesidad.png", mapa_A_lisa_congl, width = 8, height = 10, dpi = 300)
ggsave("output/mapaB_gi_conglomerado_obesidad.png",   mapa_B_gi_congl,   width = 8, height = 10, dpi = 300)

saveRDS(puntos_sf, "data/processed/puntos_analisis_espacial_obesidad.rds")


# =============================================================================
# PARTE 5. ANÁLISIS ESPACIAL A NIVEL DISTRITAL
# =============================================================================

cat("\n=====================================================\n")
cat("PARTE 5: Análisis espacial -- nivel distrital (exploratorio)\n")
cat("=====================================================\n")

prev_distrital <- base %>%
  filter(!is.na(ubigeo6)) %>%
  group_by(ubigeo6) %>%
  summarise(
    n_encuestados = n(),
    prev_obesidad = weighted.mean(obesidad, w = peso_muestral, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  filter(n_encuestados >= 3)

cat("Distritos con n>=3 encuestados:", nrow(prev_distrital), "\n")

ruta_shp_distritos <- file.path(ruta_raw, "DISTRITOS.shp")
url_distritos <- "https://raw.githubusercontent.com/juaneladio/peru-geojson/master/peru_distrital_simple.geojson"

if (file.exists(ruta_shp_distritos)) {
  distritos_sf <- st_read(ruta_shp_distritos, quiet = TRUE) %>% janitor::clean_names()
} else {
  cat("\nDescargando GeoJSON distrital desde internet (aprox 15MB)...\n")
  distritos_sf <- tryCatch(
    st_read(url_distritos, quiet = TRUE) %>% janitor::clean_names(),
    error = function(e) stop("Falló la descarga del GeoJSON distrital.")
  )
}

columna_ubigeo <- names(distritos_sf)[grepl("ubigeo|iddist|codigo", names(distritos_sf), ignore.case = TRUE)][1]
if (is.na(columna_ubigeo)) stop("No se identificó columna de UBIGEO en el shapefile distrital.")
cat("Columna UBIGEO detectada:", columna_ubigeo, "\n")

distritos_sf <- distritos_sf %>%
  mutate(ubigeo6 = str_pad(as.character(.data[[columna_ubigeo]]), 6, "left", "0"))

distritos_obesidad <- distritos_sf %>%
  inner_join(prev_distrital, by = "ubigeo6") %>%
  filter(!st_is_empty(.))

cat("Distritos con geometría + prevalencia válida:", nrow(distritos_obesidad), "\n")
if (nrow(distritos_obesidad) < 10) stop("Muy pocos distritos cruzaron con el shapefile.")

vecinos_distrito_nb <- poly2nb(distritos_obesidad, queen = TRUE)
n_islas <- sum(card(vecinos_distrito_nb) == 0)
if (n_islas > 0) cat(n_islas, "distrito(s) sin vecinos contiguos (islas)\n")

pesos_w_distrito <- nb2listw(vecinos_distrito_nb, style = "W", zero.policy = TRUE)

moran_global_distrital <- moran.test(distritos_obesidad$prev_obesidad, pesos_w_distrito, zero.policy = TRUE)
cat("\n--- Índice global de Moran (obesidad, distrital) ---\n")
print(moran_global_distrital)

moran_I_d <- unname(moran_global_distrital$estimate["Moran I statistic"])
moran_z_d <- unname(moran_global_distrital$statistic)
moran_p_d <- moran_global_distrital$p.value
cat("\nPara copiar al texto (nivel distrital):\n  ",
    sprintf("índice global de Moran %.6f, %s y z-score %.2f", moran_I_d,
            ifelse(moran_p_d < 0.001, "p < 0,001", paste0("p = ", round(moran_p_d, 3))),
            moran_z_d), "\n")

png("output/moran_scatterplot_distrital.png", width = 1600, height = 1600, res = 220)
moran.plot(distritos_obesidad$prev_obesidad, pesos_w_distrito, zero.policy = TRUE,
           xlab = "Prevalencia de obesidad (distrito)",
           ylab = "Rezago espacial (promedio de vecinos)",
           pch = 20, col = "#2c3e50", cex = 0.8,
           main = "Diagrama de dispersión de Moran -- obesidad (distrital)")
dev.off()

lisa_dist <- localmoran(distritos_obesidad$prev_obesidad, pesos_w_distrito, zero.policy = TRUE)
distritos_obesidad <- distritos_obesidad %>%
  mutate(
    lisa_p_d   = lisa_dist[, "Pr(z != E(Ii))"],
    prev_z_d   = as.numeric(scale(prev_obesidad)),
    prev_lag_d = lag.listw(pesos_w_distrito, prev_obesidad, zero.policy = TRUE),
    lag_z_d    = as.numeric(scale(prev_lag_d)),
    cluster_lisa_d = case_when(
      lisa_p_d >= 0.05 ~ "No significativo",
      prev_z_d > 0 & lag_z_d > 0 ~ "Alto-Alto",
      prev_z_d < 0 & lag_z_d < 0 ~ "Bajo-Bajo",
      prev_z_d > 0 & lag_z_d < 0 ~ "Alto-Bajo (atípico)",
      prev_z_d < 0 & lag_z_d > 0 ~ "Bajo-Alto (atípico)",
      TRUE ~ "No significativo"
    ),
    cluster_lisa_d = factor(cluster_lisa_d, levels = names(paleta_lisa))
  )

pesos_gi_distrito <- nb2listw(include.self(vecinos_distrito_nb), style = "B", zero.policy = TRUE)
gi_star_distrito  <- localG(distritos_obesidad$prev_obesidad, pesos_gi_distrito, zero.policy = TRUE)
distritos_obesidad <- distritos_obesidad %>%
  mutate(
    gi_z_d = as.numeric(gi_star_distrito),
    hotspot_d = case_when(
      gi_z_d >=  2.58 ~ "Punto caliente - 99% confianza",
      gi_z_d >=  1.96 ~ "Punto caliente - 95% confianza",
      gi_z_d >=  1.65 ~ "Punto caliente - 90% confianza",
      gi_z_d <= -2.58 ~ "Punto frío - 99% confianza",
      gi_z_d <= -1.96 ~ "Punto frío - 95% confianza",
      gi_z_d <= -1.65 ~ "Punto frío - 90% confianza",
      TRUE ~ "No significativo"
    ),
    hotspot_d = factor(hotspot_d, levels = names(paleta_gi))
  )

saveRDS(distritos_obesidad, "data/processed/distritos_analisis_espacial_obesidad.rds")

mapa_C_lisa_dist <- ggplot() +
  { if (!is.null(peru_departamentos))
    geom_sf(data = peru_departamentos, fill = NA, color = "black", linewidth = 0.6) } +
  geom_sf(data = distritos_obesidad, aes(fill = cluster_lisa_d), color = "grey40", linewidth = 0.1) +
  scale_fill_manual(values = paleta_lisa, drop = FALSE, name = "Leyenda") +
  labs(title = "C") +
  capa_norte_escala() +
  tema_mapa_paper()

mapa_D_gi_dist <- ggplot() +
  { if (!is.null(peru_departamentos))
    geom_sf(data = peru_departamentos, fill = NA, color = "black", linewidth = 0.6) } +
  geom_sf(data = distritos_obesidad, aes(fill = hotspot_d), color = "grey40", linewidth = 0.1) +
  scale_fill_manual(values = paleta_gi, drop = FALSE, name = "Leyenda") +
  labs(title = "D") +
  capa_norte_escala() +
  tema_mapa_paper()

ggsave("output/mapaC_lisa_distrital_obesidad.png", mapa_C_lisa_dist, width = 8, height = 10, dpi = 300)
ggsave("output/mapaD_gi_distrital_obesidad.png",   mapa_D_gi_dist,   width = 8, height = 10, dpi = 300)


# =============================================================================
# PARTE 6. FIGURA 1 COMBINADA (A + B + C + D)
# =============================================================================

cat("\n=====================================================\n")
cat("PARTE 6: Ensamblando Figura 1 (A-D)\n")
cat("=====================================================\n")

figura1 <- (mapa_A_lisa_congl + mapa_B_gi_congl) /
  (mapa_C_lisa_dist  + mapa_D_gi_dist) +
  plot_annotation(
    title = "Figura 1. Análisis espacial de la obesidad en adultos peruanos, ENDES 2022",
    caption = paste0(
      "A. LISA nivel conglomerado. B. Gi* nivel conglomerado.\n",
      "C. LISA distrital (exploratorio). D. Gi* distrital (exploratorio)."
    ),
    theme = theme(
      plot.title   = element_text(face = "bold", size = 16, hjust = 0.5),
      plot.caption = element_text(size = 10, hjust = 0)
    )
  )

ggsave("output/Figura1_panel_completo_obesidad.png", figura1,
       width = 14, height = 20, dpi = 350, limitsize = FALSE)

print(mapa_A_lisa_congl); print(mapa_B_gi_congl)
print(mapa_C_lisa_dist);  print(mapa_D_gi_dist)
figura1

cat("\n=====================================================\n")
cat("ANÁLISIS ESPACIAL DE OBESIDAD COMPLETADO\n")
cat("=====================================================\n")
