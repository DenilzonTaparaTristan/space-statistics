install.packages(c("sf", "gstat", "sp", "ggplot2", "dplyr", "viridis", "tmap"))

library(sf)
library(gstat)
library(sp)
library(ggplot2)
library(dplyr)

# Ajusta las rutas a donde descargaste los CSV
seca <- read.csv("D:/UNA/A/10/estadistica espacial/final/Puno_shapefile/muestras_indices_puno_seca.csv")
humeda <- read.csv("D:/UNA/A/10/estadistica espacial/final/Puno_shapefile/muestras_indices_puno_humeda.csv")

# Si tienes el .gpkg
puno <- st_read("D:/UNA/A/10/estadistica espacial/final/Puno_shapefile/provincias_puno.gpkg")

# Revisar estructura
str(seca)
head(seca)

# Ver si hay NA (nubes, bordes, etc.)
colSums(is.na(seca))
colSums(is.na(humeda))

# Limpiar: quitar filas con NA en NDVI, SAVI, EVI, NDMI
seca <- seca %>% filter(!is.na(NDVI), !is.na(SAVI), !is.na(EVI), !is.na(NDMI))
humeda <- humeda %>% filter(!is.na(NDVI), !is.na(SAVI), !is.na(EVI), !is.na(NDMI))

cat("Puntos válidos época seca:", nrow(seca), "\n")
cat("Puntos válidos época húmeda:", nrow(humeda), "\n")

library(sf)
library(dplyr)
library(jsonlite)

# Función para extraer longitud y latitud del campo .geo
extraer_coords <- function(df) {
  coords <- df$.geo %>%
    lapply(function(x) fromJSON(x)$coordinates) %>%
    do.call(rbind, .)
  df$lon <- coords[,1]
  df$lat <- coords[,2]
  df$.geo <- NULL
  return(df)
}

seca <- extraer_coords(seca)
humeda <- extraer_coords(humeda)
##########################################
# Verificar
head(seca[, c("lon","lat","NDVI")])

# Convertir a objeto espacial sf (WGS84)
seca_sf <- st_as_sf(seca, coords = c("lon","lat"), crs = 4326)
humeda_sf <- st_as_sf(humeda, coords = c("lon","lat"), crs = 4326)

# Reproyectar a UTM zona 19S (para Puno, en metros — necesario para kriging)
seca_utm <- st_transform(seca_sf, crs = 32719)
humeda_utm <- st_transform(humeda_sf, crs = 32719)

# Verificar sistema de coordenadas
st_crs(seca_utm)
plot(st_geometry(seca_utm), main = "Puntos de muestreo - Puno")


# Estadística descriptiva de los 4 índices - época seca
summary(seca[, c("NDVI","SAVI","EVI","NDMI")])

# Estadística descriptiva - época húmeda
summary(humeda[, c("NDVI","SAVI","EVI","NDMI")])

# Histogramas (para ver si necesitan transformación antes del kriging)
par(mfrow = c(2,2))
hist(seca$NDVI, main = "NDVI - Época Seca", col = "darkgreen", xlab = "NDVI")
hist(seca$SAVI, main = "SAVI - Época Seca", col = "orange", xlab = "SAVI")
hist(seca$EVI,  main = "EVI - Época Seca",  col = "forestgreen", xlab = "EVI")
hist(seca$NDMI, main = "NDMI - Época Seca", col = "steelblue", xlab = "NDMI")
par(mfrow = c(1,1))


# Filtrar valores fuera de rango físico esperado
seca <- seca %>%
  filter(EVI >= -1, EVI <= 1,
         NDVI >= -1, NDVI <= 1,
         SAVI >= -1.5, SAVI <= 1.5)

humeda <- humeda %>%
  filter(EVI >= -1, EVI <= 1,
         NDVI >= -1, NDVI <= 1,
         SAVI >= -1.5, SAVI <= 1.5)

cat("Puntos válidos época seca tras limpieza:", nrow(seca), "\n")
cat("Puntos válidos época húmeda tras limpieza:", nrow(humeda), "\n")

# Verificar rangos ya corregidos
summary(seca[, c("NDVI","SAVI","EVI","NDMI")])
summary(humeda[, c("NDVI","SAVI","EVI","NDMI")])

library(ggplot2)
library(patchwork)
library(viridis)

# Tema personalizado sofisticado, reutilizable
tema_puno <- theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(face = "bold", size = 15, hjust = 0),
    plot.subtitle = element_text(color = "grey40", size = 11),
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "grey90", linewidth = 0.3),
    axis.title = element_text(face = "bold", size = 11),
    plot.background = element_rect(fill = "white", color = NA),
    legend.position = "none"
  )

# Función para histograma sofisticado por índice
graf_hist <- function(data, var, color, titulo) {
  ggplot(data, aes(x = .data[[var]])) +
    geom_histogram(aes(y = after_stat(density)), bins = 30, 
                   fill = color, color = "white", alpha = 0.85, linewidth = 0.2) +
    geom_density(color = "grey20", linewidth = 0.8) +
    labs(title = titulo, x = var, y = "Densidad") +
    tema_puno
}

# Época seca
h1 <- graf_hist(seca, "NDVI", "#2E8B57", "NDVI — Época Seca")
h2 <- graf_hist(seca, "SAVI", "#D2691E", "SAVI — Época Seca")
h3 <- graf_hist(seca, "EVI",  "#228B22", "EVI — Época Seca")
h4 <- graf_hist(seca, "NDMI", "#4682B4", "NDMI — Época Seca")

(h1 | h2) / (h3 | h4) +
  plot_annotation(
    title = "Distribución de índices de vegetación — Provincias de Puno (Época Seca)",
    theme = theme(plot.title = element_text(face = "bold", size = 16, hjust = 0.5))
  )

# Boxplot comparativo Seca vs Húmeda (muy usado en papers de este tipo)
seca$epoca <- "Seca"
humeda$epoca <- "Húmeda"
comparativo <- bind_rows(
  seca %>% select(NDVI, SAVI, EVI, NDMI, epoca),
  humeda %>% select(NDVI, SAVI, EVI, NDMI, epoca)
)

library(tidyr)
comparativo_long <- comparativo %>%
  pivot_longer(cols = c(NDVI, SAVI, EVI, NDMI), names_to = "indice", values_to = "valor")

ggplot(comparativo_long, aes(x = indice, y = valor, fill = epoca)) +
  geom_boxplot(alpha = 0.85, outlier.size = 0.8, outlier.alpha = 0.4, width = 0.6) +
  scale_fill_manual(values = c("Seca" = "#D2691E", "Húmeda" = "#2E8B57"), name = "Época") +
  labs(
    title = "Comparación estacional de índices de vegetación",
    subtitle = "Provincias del departamento de Puno",
    x = NULL, y = "Valor del índice"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(face = "bold", size = 15),
    plot.subtitle = element_text(color = "grey40"),
    legend.position = "top",
    panel.grid.minor = element_blank()
  )


library(gstat)
library(sp)

# Convertir sf a Spatial (gstat clásico trabaja mejor con sp)
seca_sp <- as(seca_utm, "Spatial")
humeda_sp <- as(humeda_utm, "Spatial")

# Semivariograma experimental para NDVI - época seca
vgm_ndvi_seca <- variogram(NDVI ~ 1, seca_sp)
plot(vgm_ndvi_seca, main = "Semivariograma experimental - NDVI (Época Seca)")

# Ajustar modelo teórico (probamos esférico, exponencial y gaussiano)
modelo_esferico <- fit.variogram(vgm_ndvi_seca, vgm("Sph"))
modelo_exponencial <- fit.variogram(vgm_ndvi_seca, vgm("Exp"))
modelo_gaussiano <- fit.variogram(vgm_ndvi_seca, vgm("Gau"))

print(modelo_esferico)
print(modelo_exponencial)
print(modelo_gaussiano)

# Ver cuál ajusta mejor (menor SSErr)
attr(modelo_esferico, "SSErr")
attr(modelo_exponencial, "SSErr")
attr(modelo_gaussiano, "SSErr")

library(ggplot2)
library(gstat)
library(patchwork)

# Función que ajusta el mejor modelo automáticamente y devuelve variograma + modelo
ajustar_variograma <- function(formula, datos_sp) {
  vgm_exp <- variogram(formula, datos_sp)
  
  modelos <- list(
    Sph = tryCatch(fit.variogram(vgm_exp, vgm("Sph")), error = function(e) NULL),
    Exp = tryCatch(fit.variogram(vgm_exp, vgm("Exp")), error = function(e) NULL),
    Gau = tryCatch(fit.variogram(vgm_exp, vgm("Gau")), error = function(e) NULL)
  )
  
  errores <- sapply(modelos, function(m) if(!is.null(m)) attr(m, "SSErr") else Inf)
  mejor <- modelos[[which.min(errores)]]
  
  list(experimental = vgm_exp, modelo = mejor, nombre_modelo = names(errores)[which.min(errores)])
}

# Función para graficar semivariograma con estilo sofisticado
graf_variograma <- function(resultado, titulo, color) {
  vgm_exp <- resultado$experimental
  modelo <- resultado$modelo
  
  # Línea del modelo teórico ajustado
  linea <- variogramLine(modelo, maxdist = max(vgm_exp$dist))
  
  ggplot() +
    geom_point(data = vgm_exp, aes(x = dist, y = gamma), 
               color = color, size = 2.8, alpha = 0.85) +
    geom_line(data = linea, aes(x = dist, y = gamma), 
              color = "grey20", linewidth = 0.9) +
    labs(
      title = titulo,
      subtitle = paste0("Modelo: ", resultado$nombre_modelo, 
                        " | Nugget: ", round(modelo$psill[1], 4),
                        " | Sill: ", round(sum(modelo$psill), 4),
                        " | Rango: ", round(modelo$range[2]/1000, 1), " km"),
      x = "Distancia (m)", y = "Semivarianza"
    ) +
    theme_minimal(base_size = 12) +
    theme(
      plot.title = element_text(face = "bold", size = 13),
      plot.subtitle = element_text(color = "grey40", size = 9.5),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(color = "grey92", linewidth = 0.3)
    )
}

# ============================================
# Ajustar variogramas - ÉPOCA SECA
# ============================================
res_ndvi_seca <- ajustar_variograma(NDVI ~ 1, seca_sp)
res_savi_seca <- ajustar_variograma(SAVI ~ 1, seca_sp)
res_evi_seca  <- ajustar_variograma(EVI ~ 1, seca_sp)
res_ndmi_seca <- ajustar_variograma(NDMI ~ 1, seca_sp)

g1 <- graf_variograma(res_ndvi_seca, "NDVI", "#2E8B57")
g2 <- graf_variograma(res_savi_seca, "SAVI", "#D2691E")
g3 <- graf_variograma(res_evi_seca,  "EVI",  "#228B22")
g4 <- graf_variograma(res_ndmi_seca, "NDMI", "#4682B4")

(g1 | g2) / (g3 | g4) +
  plot_annotation(
    title = "Semivariogramas experimentales — Época Seca — Provincias de Puno",
    theme = theme(plot.title = element_text(face = "bold", size = 15, hjust = 0.5))
  )

# ============================================
# Ajustar variogramas - ÉPOCA HÚMEDA
# ============================================
res_ndvi_humeda <- ajustar_variograma(NDVI ~ 1, humeda_sp)
res_savi_humeda <- ajustar_variograma(SAVI ~ 1, humeda_sp)
res_evi_humeda  <- ajustar_variograma(EVI ~ 1, humeda_sp)
res_ndmi_humeda <- ajustar_variograma(NDMI ~ 1, humeda_sp)

h1 <- graf_variograma(res_ndvi_humeda, "NDVI", "#2E8B57")
h2 <- graf_variograma(res_savi_humeda, "SAVI", "#D2691E")
h3 <- graf_variograma(res_evi_humeda,  "EVI",  "#228B22")
h4 <- graf_variograma(res_ndmi_humeda, "NDMI", "#4682B4")

(h1 | h2) / (h3 | h4) +
  plot_annotation(
    title = "Semivariogramas experimentales — Época Húmeda — Provincias de Puno",
    theme = theme(plot.title = element_text(face = "bold", size = 15, hjust = 0.5))
  )


library(sf)
library(sp)

# Reconstruir objetos espaciales DESDE LOS DATOS YA LIMPIOS (post Paso 3.5)
seca_sf   <- st_as_sf(seca, coords = c("lon","lat"), crs = 4326)
humeda_sf <- st_as_sf(humeda, coords = c("lon","lat"), crs = 4326)

seca_utm   <- st_transform(seca_sf, crs = 32719)
humeda_utm <- st_transform(humeda_sf, crs = 32719)

seca_sp   <- as(seca_utm, "Spatial")
humeda_sp <- as(humeda_utm, "Spatial")

# Verificar rápido que EVI ya esté en rango correcto
summary(seca_sp$EVI)
summary(humeda_sp$EVI)

res_evi_seca   <- ajustar_variograma(EVI ~ 1, seca_sp)
res_evi_humeda <- ajustar_variograma(EVI ~ 1, humeda_sp)

g3 <- graf_variograma(res_evi_seca,  "EVI", "#228B22")
h3 <- graf_variograma(res_evi_humeda, "EVI", "#228B22")

# Recompón las figuras completas
(g1 | g2) / (g3 | g4) +
  plot_annotation(
    title = "Semivariogramas experimentales — Época Seca — Provincias de Puno",
    theme = theme(plot.title = element_text(face = "bold", size = 15, hjust = 0.5))
  )

(h1 | h2) / (h3 | h4) +
  plot_annotation(
    title = "Semivariogramas experimentales — Época Húmeda — Provincias de Puno",
    theme = theme(plot.title = element_text(face = "bold", size = 15, hjust = 0.5))
  )

library(gstat)
library(sp)
library(sf)

# 1. Crear grilla de predicción sobre el área de Puno
bbox_puno <- st_bbox(st_transform(puno, crs = 32719))

grilla_pred <- expand.grid(
  x = seq(bbox_puno["xmin"], bbox_puno["xmax"], by = 2000),  # resolución 2 km
  y = seq(bbox_puno["ymin"], bbox_puno["ymax"], by = 2000)
)
coordinates(grilla_pred) <- ~x + y
gridded(grilla_pred) <- TRUE
proj4string(grilla_pred) <- CRS("+init=epsg:32719")

# 2. Recortar la grilla para que solo cubra el polígono de Puno (no el rectángulo completo)
puno_utm_sp <- as(st_transform(puno, crs = 32719), "Spatial")
grilla_sf <- st_as_sf(grilla_pred)
puno_union <- st_union(st_transform(puno, crs = 32719))
dentro <- st_intersects(grilla_sf, puno_union, sparse = FALSE)[,1]
grilla_pred <- grilla_pred[dentro, ]

cat("Puntos de la grilla dentro de Puno:", length(grilla_pred), "\n")
###################
install.packages(c("ggspatial", "viridis", "ggrepel", "patchwork"))


library(gstat)
library(sf)
library(ggplot2)
library(ggspatial)
library(viridis)
library(ggrepel)
library(patchwork)
library(dplyr)

# ============================================
# 1. Función para ejecutar kriging y devolver data.frame listo para graficar
# ============================================
hacer_kriging <- function(formula, datos_sp, modelo, grilla) {
  resultado <- krige(formula, datos_sp, grilla, model = modelo)
  df <- as.data.frame(resultado)
  colnames(df)[1:2] <- c("x", "y")
  return(df)
}

# ============================================
# 2. Ejecutar kriging para los 8 casos (4 índices x 2 épocas)
# ============================================
k_ndvi_seca   <- hacer_kriging(NDVI ~ 1, seca_sp,   res_ndvi_seca$modelo,   grilla_pred)
k_savi_seca   <- hacer_kriging(SAVI ~ 1, seca_sp,   res_savi_seca$modelo,   grilla_pred)
k_evi_seca    <- hacer_kriging(EVI ~ 1,  seca_sp,   res_evi_seca$modelo,    grilla_pred)
k_ndmi_seca   <- hacer_kriging(NDMI ~ 1, seca_sp,   res_ndmi_seca$modelo,   grilla_pred)

k_ndvi_humeda <- hacer_kriging(NDVI ~ 1, humeda_sp, res_ndvi_humeda$modelo, grilla_pred)
k_savi_humeda <- hacer_kriging(SAVI ~ 1, humeda_sp, res_savi_humeda$modelo, grilla_pred)
k_evi_humeda  <- hacer_kriging(EVI ~ 1,  humeda_sp, res_evi_humeda$modelo,  grilla_pred)
k_ndmi_humeda <- hacer_kriging(NDMI ~ 1, humeda_sp, res_ndmi_humeda$modelo, grilla_pred)

cat("Kriging completado. Resumen NDVI época seca:\n")
summary(k_ndvi_seca$var1.pred)


library(ggplot2)
library(ggspatial)
library(viridis)
library(ggrepel)
library(patchwork)
library(sf)
library(dplyr)

# ============================================
# 1. Preparar polígono de Puno para overlay y etiquetas
# ============================================
puno_utm <- st_transform(puno, crs = 32719)

# Centroides para etiquetas de provincias (ajusta el nombre de columna si no es "PROVINCIA")
puno_centroides <- st_centroid(puno_utm)
puno_centroides_coords <- cbind(
  st_drop_geometry(puno_centroides),
  st_coordinates(puno_centroides)
)

# ============================================
# 2. Función para generar mapa de kriging sofisticado
# ============================================
mapa_kriging <- function(datos_krige, titulo, subtitulo, paleta = "viridis") {
  ggplot() +
    geom_raster(data = datos_krige, aes(x = x, y = y, fill = var1.pred)) +
    geom_sf(data = puno_utm, fill = NA, color = "white", linewidth = 0.4, inherit.aes = FALSE) +
    geom_text_repel(
      data = puno_centroides_coords,
      aes(x = X, y = Y, label = PROVINCIA),
      size = 2.8, color = "white", fontface = "bold",
      bg.color = "black", bg.r = 0.12,
      max.overlaps = 20, seed = 42
    ) +
    scale_fill_viridis_c(option = paleta, name = titulo) +
    annotation_scale(location = "bl", width_hint = 0.25, 
                     text_col = "white", line_col = "white") +
    annotation_north_arrow(location = "tr", which_north = "true",
                           style = north_arrow_fancy_orienteering(
                             fill = c("white", "white"), line_col = "white")) +
    labs(title = subtitulo, x = NULL, y = NULL) +
    coord_sf(expand = FALSE) +
    theme_minimal(base_size = 11) +
    theme(
      plot.title = element_text(face = "bold", size = 13, hjust = 0.5),
      panel.background = element_rect(fill = "grey10", color = NA),
      panel.grid = element_blank(),
      axis.text = element_text(size = 7, color = "grey40"),
      legend.position = "right",
      legend.title = element_text(size = 9, face = "bold"),
      legend.key.height = unit(1.2, "cm")
    )
}

# ============================================
# 3. Generar los 8 mapas
# ============================================
m1 <- mapa_kriging(k_ndvi_seca, "NDVI", "NDVI — Época Seca", "viridis")
m2 <- mapa_kriging(k_savi_seca, "SAVI", "SAVI — Época Seca", "mako")
m3 <- mapa_kriging(k_evi_seca,  "EVI",  "EVI — Época Seca",  "viridis")
m4 <- mapa_kriging(k_ndmi_seca, "NDMI", "NDMI — Época Seca", "mako")

m5 <- mapa_kriging(k_ndvi_humeda, "NDVI", "NDVI — Época Húmeda", "viridis")
m6 <- mapa_kriging(k_savi_humeda, "SAVI", "SAVI — Época Húmeda", "mako")
m7 <- mapa_kriging(k_evi_humeda,  "EVI",  "EVI — Época Húmeda",  "viridis")
m8 <- mapa_kriging(k_ndmi_humeda, "NDMI", "NDMI — Época Húmeda", "mako")

# ============================================
# 4. Panel comparativo: Época Seca (2x2)
# ============================================
(m1 | m2) / (m3 | m4) +
  plot_annotation(
    title = "Interpolación por Kriging de índices de vegetación — Época Seca",
    subtitle = "Provincias del departamento de Puno, Perú",
    theme = theme(
      plot.title = element_text(face = "bold", size = 17, hjust = 0.5),
      plot.subtitle = element_text(size = 11, color = "grey40", hjust = 0.5)
    )
  )

ggsave("mapa_NDVI_seca.png", plot = m1, width = 8, height = 7, dpi = 300, bg = "white")
ggsave("mapa_SAVI_seca.png", plot = m2, width = 8, height = 7, dpi = 300, bg = "white")
ggsave("mapa_EVI_seca.png",  plot = m3, width = 8, height = 7, dpi = 300, bg = "white")
ggsave("mapa_NDMI_seca.png", plot = m4, width = 8, height = 7, dpi = 300, bg = "white")


(m5 | m6) / (m7 | m8) +
  plot_annotation(
    title = "Interpolación por Kriging de índices de vegetación — Época Húmeda",
    subtitle = "Provincias del departamento de Puno, Perú",
    theme = theme(
      plot.title = element_text(face = "bold", size = 17, hjust = 0.5),
      plot.subtitle = element_text(size = 11, color = "grey40", hjust = 0.5)
    )
  )

ggsave("kriging_epoca_humeda.png", width = 14, height = 12, dpi = 300, bg = "white")

ggsave("mapa_NDVI_humeda.png", plot = m5, width = 8, height = 7, dpi = 300, bg = "white")
ggsave("mapa_SAVI_humeda.png", plot = m6, width = 8, height = 7, dpi = 300, bg = "white")
ggsave("mapa_EVI_humeda.png",  plot = m7, width = 8, height = 7, dpi = 300, bg = "white")
ggsave("mapa_NDMI_humeda.png", plot = m8, width = 8, height = 7, dpi = 300, bg = "white")


library(gstat)
library(sp)
library(dplyr)

# Definir cortes con base en los terciles de NDVI (época seca)
cortes_ndvi <- quantile(seca$NDVI, probs = c(0.33, 0.66))
print(cortes_ndvi)

# Esto nos da 2 umbrales -> 3 categorías:
# Baja: NDVI < corte1
# Media: corte1 <= NDVI < corte2  
# Alta: NDVI >= corte2

# Función para indicator kriging: crea indicador, ajusta variograma, krigea
kriging_indicativo <- function(datos_sp, variable, corte, grilla) {
  # Crear indicador binario: 1 si el valor es <= corte, 0 si no
  datos_sp$indicador <- ifelse(datos_sp[[variable]] <= corte, 1, 0)
  
  # Ajustar semivariograma del indicador
  vgm_ind <- variogram(indicador ~ 1, datos_sp)
  modelo_ind <- tryCatch(
    fit.variogram(vgm_ind, vgm("Sph")),
    error = function(e) fit.variogram(vgm_ind, vgm("Exp"))
  )
  
  # Kriging del indicador (da la PROBABILIDAD de estar por debajo del corte)
  resultado <- krige(indicador ~ 1, datos_sp, grilla, model = modelo_ind)
  df <- as.data.frame(resultado)
  colnames(df)[1:2] <- c("x", "y")
  
  # Asegurar que las probabilidades queden entre 0 y 1
  df$var1.pred <- pmin(pmax(df$var1.pred, 0), 1)
  
  return(list(datos = df, modelo = modelo_ind, vgm_exp = vgm_ind))
}

# Aplicar los 2 cortes para NDVI época seca
ik_corte1_seca <- kriging_indicativo(seca_sp, "NDVI", cortes_ndvi[1], grilla_pred)
ik_corte2_seca <- kriging_indicativo(seca_sp, "NDVI", cortes_ndvi[2], grilla_pred)

cat("Modelo indicador corte 1 (33%):\n")
print(ik_corte1_seca$modelo)
cat("\nModelo indicador corte 2 (66%):\n")
print(ik_corte2_seca$modelo)

# Reajustar el corte 2 con un rango inicial más razonable (similar al de NDVI continuo, ~100km)
vgm_ind2 <- variogram(indicador ~ 1, {
  seca_sp$indicador <- ifelse(seca_sp$NDVI <= cortes_ndvi[2], 1, 0)
  seca_sp
})

modelo_ind2_corregido <- fit.variogram(
  vgm_ind2, 
  vgm(psill = 0.15, model = "Sph", range = 100000, nugget = 0.18)
)

print(modelo_ind2_corregido)
attr(modelo_ind2_corregido, "SSErr")

# Visualizar para confirmar que se ve razonable
plot(vgm_ind2, modelo_ind2_corregido, main = "Semivariograma indicador - Corte 66% (corregido)")

# Forzar el rango a un valor fijo razonable (no dejar que el optimizador lo mueva)
modelo_ind2_corregido <- fit.variogram(
  vgm_ind2, 
  vgm(psill = 0.15, model = "Sph", range = 120000, nugget = 0.18),
  fit.ranges = FALSE  # <- clave: fija el rango en 100000 m
)

print(modelo_ind2_corregido)
attr(modelo_ind2_corregido, "SSErr")

plot(vgm_ind2, modelo_ind2_corregido, main = "Semivariograma indicador - Corte 66% (rango fijo)")

resultado2 <- krige(indicador ~ 1, seca_sp, grilla_pred, model = modelo_ind2_corregido)
df2 <- as.data.frame(resultado2)
colnames(df2)[1:2] <- c("x", "y")
df2$var1.pred <- pmin(pmax(df2$var1.pred, 0), 1)

ik_corte2_seca <- list(datos = df2, modelo = modelo_ind2_corregido, vgm_exp = vgm_ind2)

cat("Kriging del corte 2 completado. Resumen probabilidades:\n")
summary(df2$var1.pred)


library(dplyr)

# Combinar ambos indicadores (deben tener las mismas coordenadas x,y)
clasificacion <- ik_corte1_seca$datos %>%
  select(x, y, prob_bajo1 = var1.pred) %>%
  left_join(
    ik_corte2_seca$datos %>% select(x, y, prob_bajo2 = var1.pred),
    by = c("x", "y")
  )

# Lógica de kriging indicativo:
# P(Baja) = prob_bajo1
# P(Media) = prob_bajo2 - prob_bajo1
# P(Alta) = 1 - prob_bajo2
clasificacion <- clasificacion %>%
  mutate(
    prob_baja  = prob_bajo1,
    prob_media = pmax(prob_bajo2 - prob_bajo1, 0),
    prob_alta  = 1 - prob_bajo2
  )

# Asignar la categoría con mayor probabilidad en cada punto
clasificacion <- clasificacion %>%
  rowwise() %>%
  mutate(
    categoria = c("Baja", "Media", "Alta")[which.max(c(prob_baja, prob_media, prob_alta))]
  ) %>%
  ungroup()

clasificacion$categoria <- factor(clasificacion$categoria, levels = c("Baja", "Media", "Alta"))

table(clasificacion$categoria)

library(ggplot2)
library(ggspatial)
library(ggrepel)
library(sf)

mapa_clasificacion <- ggplot() +
  geom_raster(data = clasificacion, aes(x = x, y = y, fill = categoria)) +
  geom_sf(data = puno_utm, fill = NA, color = "white", linewidth = 0.4, inherit.aes = FALSE) +
  geom_text_repel(
    data = puno_centroides_coords,
    aes(x = X, y = Y, label = PROVINCIA),
    size = 3, color = "white", fontface = "bold",
    bg.color = "black", bg.r = 0.12,
    max.overlaps = 20, seed = 42
  ) +
  scale_fill_manual(
    values = c("Baja" = "#B22222", "Media" = "#DAA520", "Alta" = "#2E8B57"),
    name = "Categoría\nde vegetación\n(NDVI)"
  ) +
  annotation_scale(location = "bl", width_hint = 0.25, 
                   text_col = "white", line_col = "white") +
  annotation_north_arrow(location = "tr", which_north = "true",
                         style = north_arrow_fancy_orienteering(
                           fill = c("white", "white"), line_col = "white")) +
  labs(
    title = "Clasificación espacial de vegetación por Kriging Indicativo",
    subtitle = "NDVI — Época Seca — Provincias de Puno, Perú",
    caption = paste0("Cortes: Baja < ", round(cortes_ndvi[1],3), 
                     " | Media: ", round(cortes_ndvi[1],3), "–", round(cortes_ndvi[2],3),
                     " | Alta ≥ ", round(cortes_ndvi[2],3)),
    x = NULL, y = NULL
  ) +
  coord_sf(expand = FALSE) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 14, hjust = 0.5),
    plot.subtitle = element_text(size = 10, color = "grey30", hjust = 0.5),
    plot.caption = element_text(size = 8, color = "grey50"),
    panel.background = element_rect(fill = "grey10", color = NA),
    panel.grid = element_blank(),
    axis.text = element_text(size = 7, color = "grey40"),
    legend.position = "right",
    legend.title = element_text(size = 9, face = "bold")
  )

mapa_clasificacion

ggsave("mapa_clasificacion_kriging_indicativo.png", plot = mapa_clasificacion,
       width = 9, height = 8, dpi = 300, bg = "white")

# Kriging época húmeda (objetos m5, m6, m7, m8 ya existen)
ggsave("C:/Users/robin/OneDrive/Documentos/mapa_NDVI_humeda.png", plot = m5, width = 8, height = 7, dpi = 300, bg = "white")
ggsave("C:/Users/robin/OneDrive/Documentos/mapa_SAVI_humeda.png", plot = m6, width = 8, height = 7, dpi = 300, bg = "white")
ggsave("C:/Users/robin/OneDrive/Documentos/mapa_EVI_humeda.png",  plot = m7, width = 8, height = 7, dpi = 300, bg = "white")
ggsave("C:/Users/robin/OneDrive/Documentos/mapa_NDMI_humeda.png", plot = m8, width = 8, height = 7, dpi = 300, bg = "white")

# Clasificación kriging indicativo (objeto mapa_clasificacion)
ggsave("C:/Users/robin/OneDrive/Documentos/mapa_clasificacion_kriging_indicativo.png", 
       plot = mapa_clasificacion, width = 9, height = 8, dpi = 300, bg = "white")

# Paneles de semivariogramas (reconstruye y guarda, usando los objetos g1-g4, h1-h4)
library(patchwork)
ggsave("C:/Users/robin/OneDrive/Documentos/semivariogramas_seca.png",
       plot = (g1 | g2) / (g3 | g4), width = 11, height = 8, dpi = 300, bg = "white")
ggsave("C:/Users/robin/OneDrive/Documentos/semivariogramas_humeda.png",
       plot = (h1 | h2) / (h3 | h4), width = 11, height = 8, dpi = 300, bg = "white")

library(ggplot2)
library(patchwork)
library(dplyr)
library(tidyr)

# ============================================
# Regenerar histogramas (rápido, no requiere kriging)
# ============================================
graf_hist <- function(data, var, color, titulo) {
  ggplot(data, aes(x = .data[[var]])) +
    geom_histogram(aes(y = after_stat(density)), bins = 30, 
                   fill = color, color = "white", alpha = 0.85, linewidth = 0.2) +
    geom_density(color = "grey20", linewidth = 0.8) +
    labs(title = titulo, x = var, y = "Densidad") +
    theme_minimal(base_size = 13) +
    theme(plot.title = element_text(face = "bold", size = 13))
}

hist1 <- graf_hist(seca, "NDVI", "#2E8B57", "NDVI — Época Seca")
hist2 <- graf_hist(seca, "SAVI", "#D2691E", "SAVI — Época Seca")
hist3 <- graf_hist(seca, "EVI",  "#228B22", "EVI — Época Seca")
hist4 <- graf_hist(seca, "NDMI", "#4682B4", "NDMI — Época Seca")

panel_histogramas <- (hist1 | hist2) / (hist3 | hist4) +
  plot_annotation(title = "Distribución de índices de vegetación — Puno (Época Seca)")

ggsave("C:/Users/robin/OneDrive/Documentos/histogramas_seca.png", 
       plot = panel_histogramas, width = 11, height = 8, dpi = 300, bg = "white")

# ============================================
# Regenerar boxplot comparativo (Seca vs Húmeda)
# ============================================
seca$epoca <- "Seca"
humeda$epoca <- "Húmeda"
comparativo <- bind_rows(
  seca %>% select(NDVI, SAVI, EVI, NDMI, epoca),
  humeda %>% select(NDVI, SAVI, EVI, NDMI, epoca)
) %>%
  pivot_longer(cols = c(NDVI, SAVI, EVI, NDMI), names_to = "indice", values_to = "valor")

boxplot_comparativo <- ggplot(comparativo, aes(x = indice, y = valor, fill = epoca)) +
  geom_boxplot(alpha = 0.85, outlier.size = 0.8, outlier.alpha = 0.4, width = 0.6) +
  scale_fill_manual(values = c("Seca" = "#D2691E", "Húmeda" = "#2E8B57"), name = "Época") +
  labs(title = "Comparación estacional de índices de vegetación",
       subtitle = "Provincias del departamento de Puno", x = NULL, y = "Valor del índice") +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold", size = 15), legend.position = "top")

ggsave("C:/Users/robin/OneDrive/Documentos/boxplot_comparativo.png", 
       plot = boxplot_comparativo, width = 10, height = 7, dpi = 300, bg = "white")


library(gstat)
library(sp)
library(dplyr)
library(ggplot2)
library(ggspatial)
library(ggrepel)
library(sf)

# ============================================
# 1. Definir cortes (terciles) para NDVI - época húmeda
# ============================================
cortes_ndvi_humeda <- quantile(humeda$NDVI, probs = c(0.33, 0.66))
print(cortes_ndvi_humeda)

# ============================================
# 2. Kriging del indicador - Corte 1 (33%)
# ============================================
humeda_sp$indicador1 <- ifelse(humeda_sp$NDVI <= cortes_ndvi_humeda[1], 1, 0)
vgm_ind1_humeda <- variogram(indicador1 ~ 1, humeda_sp)

modelo_ind1_humeda <- fit.variogram(
  vgm_ind1_humeda,
  vgm(psill = 0.15, model = "Sph", range = 50000, nugget = 0.15),
  fit.ranges = FALSE
)
print(modelo_ind1_humeda)
plot(vgm_ind1_humeda, modelo_ind1_humeda, main = "Indicador Corte 33% - Húmeda")

resultado1_humeda <- krige(indicador1 ~ 1, humeda_sp, grilla_pred, model = modelo_ind1_humeda)
df1_humeda <- as.data.frame(resultado1_humeda)
colnames(df1_humeda)[1:2] <- c("x", "y")
df1_humeda$var1.pred <- pmin(pmax(df1_humeda$var1.pred, 0), 1)

# ============================================
# 3. Kriging del indicador - Corte 2 (66%)
# ============================================
humeda_sp$indicador2 <- ifelse(humeda_sp$NDVI <= cortes_ndvi_humeda[2], 1, 0)
vgm_ind2_humeda <- variogram(indicador2 ~ 1, humeda_sp)

modelo_ind2_humeda <- fit.variogram(
  vgm_ind2_humeda,
  vgm(psill = 0.15, model = "Sph", range = 50000, nugget = 0.15),
  fit.ranges = FALSE
)
print(modelo_ind2_humeda)
plot(vgm_ind2_humeda, modelo_ind2_humeda, main = "Indicador Corte 66% - Húmeda")

resultado2_humeda <- krige(indicador2 ~ 1, humeda_sp, grilla_pred, model = modelo_ind2_humeda)
df2_humeda <- as.data.frame(resultado2_humeda)
colnames(df2_humeda)[1:2] <- c("x", "y")
df2_humeda$var1.pred <- pmin(pmax(df2_humeda$var1.pred, 0), 1)

# ============================================
# 4. Combinar ambos indicadores en categorías
# ============================================
clasificacion_humeda <- df1_humeda %>%
  select(x, y, prob_bajo1 = var1.pred) %>%
  left_join(df2_humeda %>% select(x, y, prob_bajo2 = var1.pred), by = c("x", "y")) %>%
  mutate(
    prob_baja  = prob_bajo1,
    prob_media = pmax(prob_bajo2 - prob_bajo1, 0),
    prob_alta  = 1 - prob_bajo2
  ) %>%
  rowwise() %>%
  mutate(categoria = c("Baja", "Media", "Alta")[which.max(c(prob_baja, prob_media, prob_alta))]) %>%
  ungroup()

clasificacion_humeda$categoria <- factor(clasificacion_humeda$categoria, levels = c("Baja", "Media", "Alta"))

table(clasificacion_humeda$categoria)

# ============================================
# 5. Mapa final (mismo estilo que época seca)
# ============================================
mapa_clasificacion_humeda <- ggplot() +
  geom_raster(data = clasificacion_humeda, aes(x = x, y = y, fill = categoria)) +
  geom_sf(data = puno_utm, fill = NA, color = "white", linewidth = 0.4, inherit.aes = FALSE) +
  geom_text_repel(
    data = puno_centroides_coords,
    aes(x = X, y = Y, label = PROVINCIA),
    size = 3, color = "white", fontface = "bold",
    bg.color = "black", bg.r = 0.12,
    max.overlaps = 20, seed = 42
  ) +
  scale_fill_manual(
    values = c("Baja" = "#B22222", "Media" = "#DAA520", "Alta" = "#2E8B57"),
    name = "Categoría\nde vegetación\n(NDVI)"
  ) +
  annotation_scale(location = "bl", width_hint = 0.25, text_col = "white", line_col = "white") +
  annotation_north_arrow(location = "tr", which_north = "true",
                         style = north_arrow_fancy_orienteering(fill = c("white","white"), line_col = "white")) +
  labs(
    title = "Clasificación espacial de vegetación por Kriging Indicativo",
    subtitle = "NDVI — Época Húmeda — Provincias de Puno, Perú",
    caption = paste0("Cortes: Baja < ", round(cortes_ndvi_humeda[1],3),
                     " | Media: ", round(cortes_ndvi_humeda[1],3), "–", round(cortes_ndvi_humeda[2],3),
                     " | Alta ≥ ", round(cortes_ndvi_humeda[2],3)),
    x = NULL, y = NULL
  ) +
  coord_sf(expand = FALSE) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 14, hjust = 0.5),
    plot.subtitle = element_text(size = 10, color = "grey30", hjust = 0.5),
    plot.caption = element_text(size = 8, color = "grey50"),
    panel.background = element_rect(fill = "grey10", color = NA),
    panel.grid = element_blank(),
    axis.text = element_text(size = 7, color = "grey40"),
    legend.position = "right",
    legend.title = element_text(size = 9, face = "bold")
  )

mapa_clasificacion_humeda

ggsave("C:/Users/robin/OneDrive/Documentos/mapa_clasificacion_kriging_indicativo_humeda.png",
       plot = mapa_clasificacion_humeda, width = 9, height = 8, dpi = 300, bg = "white")



