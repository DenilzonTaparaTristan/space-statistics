#===============================================================================
# ANÁLISIS DE SERIES DE TIEMPO — BOFEDALES DE CARABAYA, PUNO
# NDVI/SAVI/EVI/NDMI (2019-2025) — SARIMA, tendencia, clima y pronóstico
#===============================================================================

# =============================================================================
# 0. LIBRERÍAS Y CONFIGURACIÓN
# =============================================================================
library(dplyr)
library(tidyr)
library(lubridate)
library(zoo)
library(tseries)
library(forecast)
library(Kendall)
library(ggplot2)
library(patchwork)
library(sf)
library(ggspatial)
library(ggrepel)

ruta            <- "D:/UNA/A/10/estadistica espacial/final/articulo/bof/"
ruta_geo        <- "D:/UNA/A/10/estadistica espacial/final/articulo/bofedales_carabaya_correcto.gpkg"
ruta_provincias <- "D:/UNA/A/10/estadistica espacial/final/Puno_shapefile/provincias_puno.gpkg"

columnas_indices <- c("NDVI_bofedal","SAVI_bofedal","EVI_bofedal","NDMI_bofedal",
                      "NDVI_control","SAVI_control","EVI_control","NDMI_control")


# =============================================================================
# 1. CARGA Y LIMPIEZA DE DATOS
# =============================================================================
vegetacion <- read.csv(paste0(ruta, "serie_temporal_indices_carabaya_2017_2025.csv"))
clima      <- read.csv(paste0(ruta, "serie_temporal_clima_carabaya_2017_2025.csv"))

serie <- vegetacion %>%
  left_join(clima, by = "fecha") %>%
  mutate(fecha = ym(fecha)) %>%
  arrange(fecha) %>%
  mutate(across(all_of(columnas_indices), ~ na_if(., -9999))) %>%
  # Recorte a partir de 2019-01: Sentinel-2 L2A no tiene cobertura confiable antes
  # (corrección atmosférica Sen2Cor no operativa a nivel global hasta fines de 2018)
  filter(fecha >= as.Date("2019-01-01")) %>%
  # Interpolación de huecos sueltos por nubosidad + extrapolación en extremos (rule=2)
  mutate(across(all_of(columnas_indices),
                ~ na.approx(., x = fecha, na.rm = FALSE, rule = 2)))

cat("Meses en la serie limpia:", nrow(serie), "| NA restantes:",
    sum(is.na(serie[, columnas_indices])), "\n")

write.csv(serie, paste0(ruta, "serie_limpia_carabaya_2019_2025.csv"), row.names = FALSE)


# =============================================================================
# 2. OBJETOS DE SERIE DE TIEMPO
# =============================================================================
ts_ndvi_bofedal  <- ts(serie$NDVI_bofedal,     start = c(2019,1), frequency = 12)
ts_savi_bofedal  <- ts(serie$SAVI_bofedal,     start = c(2019,1), frequency = 12)
ts_evi_bofedal   <- ts(serie$EVI_bofedal,      start = c(2019,1), frequency = 12)
ts_ndmi_bofedal  <- ts(serie$NDMI_bofedal,     start = c(2019,1), frequency = 12)
ts_ndvi_control  <- ts(serie$NDVI_control,     start = c(2019,1), frequency = 12)
ts_savi_control  <- ts(serie$SAVI_control,     start = c(2019,1), frequency = 12)
ts_evi_control   <- ts(serie$EVI_control,      start = c(2019,1), frequency = 12)
ts_ndmi_control  <- ts(serie$NDMI_control,     start = c(2019,1), frequency = 12)
ts_precip        <- ts(serie$precipitacion_mm, start = c(2019,1), frequency = 12)
ts_temp          <- ts(serie$temperatura_C,    start = c(2019,1), frequency = 12)


# =============================================================================
# 3. VISUALIZACIÓN: SERIES BOFEDAL VS. CONTROL
# =============================================================================
# Hallazgos: estacionalidad marcada (picos mar-may, valles ago-oct); el bofedal
# se mantiene sistemáticamente por encima del control en NDVI/EVI/NDMI (retiene
# humedad en seca); no hay caída dramática de tendencia 2019-2025 a simple vista.
serie_larga <- serie %>%
  select(fecha, all_of(columnas_indices)) %>%
  pivot_longer(cols = -fecha, names_to = "variable", values_to = "valor") %>%
  mutate(indice = sub("_.*", "", variable),
         zona   = ifelse(grepl("bofedal", variable), "Bofedal", "Control"))

panel_series <- ggplot(serie_larga, aes(x = fecha, y = valor, color = zona)) +
  geom_line(linewidth = 0.6) +
  facet_wrap(~indice, scales = "free_y", ncol = 2) +
  scale_color_manual(values = c(Bofedal = "#2E8B57", Control = "#D2691E")) +
  labs(title = "Series de tiempo mensuales (2019-2025) — Bofedal vs. Control",
       subtitle = "Carabaya, Puno", x = NULL, y = "Valor del índice", color = NULL) +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold", size = 14), legend.position = "top")

ggsave(paste0(ruta, "panel_series_temporales.png"), panel_series, width = 12, height = 8, dpi = 300, bg = "white")


# =============================================================================
# 4. DESCOMPOSICIÓN STL Y PRUEBAS DE ESTACIONARIEDAD (NDVI bofedal, referencia)
# =============================================================================
# ADF p=0.01 (estacionaria) + KPSS p=0.1 (estacionaria) -> resultado robusto.
# ndiffs=0, nsdiffs=1 -> se usará d=0, D=1 en todos los SARIMA.
png(paste0(ruta, "stl_ndvi_bofedal.png"), width = 1000, height = 700, res = 120)
plot(stl(ts_ndvi_bofedal, s.window = "periodic"), main = "Descomposición STL - NDVI Bofedal")
dev.off()

png(paste0(ruta, "stl_evi_bofedal.png"), width = 1000, height = 700, res = 120)
plot(stl(ts_evi_bofedal, s.window = "periodic"), main = "Descomposición STL - EVI Bofedal")
dev.off()

png(paste0(ruta, "stl_ndmi_bofedal.png"), width = 1000, height = 700, res = 120)
plot(stl(ts_ndmi_bofedal, s.window = "periodic"), main = "Descomposición STL - NDMI Bofedal")
dev.off()

png(paste0(ruta, "stl_savi_bofedal.png"), width = 1000, height = 700, res = 120)
plot(stl(ts_savi_bofedal, s.window = "periodic"), main = "Descomposición STL - SAVI Bofedal")
dev.off()

adf.test(ts_ndvi_bofedal)
kpss.test(ts_ndvi_bofedal)
ndiffs(ts_ndvi_bofedal)
nsdiffs(ts_ndvi_bofedal)


# =============================================================================
# 5. AJUSTE SARIMA — LOS 8 MODELOS (bofedal y control x 4 índices)
# =============================================================================
ajustar_sarima <- function(serie_ts, nombre) {
  modelo <- auto.arima(serie_ts, d = ndiffs(serie_ts), D = nsdiffs(serie_ts),
                       seasonal = TRUE, stepwise = FALSE, approximation = FALSE)
  lb <- checkresiduals(modelo, plot = FALSE)
  cat("\n=====", nombre, "| Orden:", paste(arimaorder(modelo), collapse = ","),
      "| Ljung-Box p:", round(lb$p.value, 4), "=====\n")
  print(modelo)
  list(modelo = modelo, ljung_box_p = lb$p.value, aic = modelo$aic)
}

modelo_ndvi_bofedal <- ajustar_sarima(ts_ndvi_bofedal, "NDVI Bofedal")$modelo
res_savi_bofedal    <- ajustar_sarima(ts_savi_bofedal, "SAVI Bofedal")
res_evi_bofedal     <- ajustar_sarima(ts_evi_bofedal,  "EVI Bofedal")
res_ndmi_bofedal     <- ajustar_sarima(ts_ndmi_bofedal, "NDMI Bofedal")
res_ndvi_control     <- ajustar_sarima(ts_ndvi_control, "NDVI Control")
res_savi_control     <- ajustar_sarima(ts_savi_control, "SAVI Control")
res_evi_control      <- ajustar_sarima(ts_evi_control,  "EVI Control")
res_ndmi_control     <- ajustar_sarima(ts_ndmi_control, "NDMI Control")

# Guardar diagnóstico de residuos del modelo principal (NDVI bofedal)
png(paste0(ruta, "residuos_ndvi_bofedal.png"), width = 1000, height = 700, res = 120)
checkresiduals(modelo_ndvi_bofedal)
dev.off()

# NOTA: NDMI Control salió sin componente estacional (ARIMA(2,0,1) puro) —
# sugiere que el pastizal control NO sigue un ciclo estacional tan regular como
# el bofedal (depende de eventos de lluvia erráticos, no de retención de agua).
# Por eso NO se compara su AIC directamente con los demás (distinta transformación);
# se usa RMSE de validación cruzada en el paso 6, que sí es comparable entre todos.


# =============================================================================
# 6. TABLA COMPARATIVA FINAL (RMSE por validación cruzada — métrica justa)
# =============================================================================
calcular_rmse_cv <- function(serie_ts) {
  errores <- tsCV(serie_ts, forecastfunction = function(x, h)
    forecast(auto.arima(x, stepwise = TRUE, approximation = TRUE), h = h), h = 1)
  sqrt(mean(errores^2, na.rm = TRUE))
}

resultados <- list(
  "NDVI Bofedal" = list(mod = modelo_ndvi_bofedal,      ts = ts_ndvi_bofedal),
  "SAVI Bofedal" = list(mod = res_savi_bofedal$modelo,  ts = ts_savi_bofedal),
  "EVI Bofedal"  = list(mod = res_evi_bofedal$modelo,   ts = ts_evi_bofedal),
  "NDMI Bofedal" = list(mod = res_ndmi_bofedal$modelo,  ts = ts_ndmi_bofedal),
  "NDVI Control" = list(mod = res_ndvi_control$modelo,  ts = ts_ndvi_control),
  "SAVI Control" = list(mod = res_savi_control$modelo,  ts = ts_savi_control),
  "EVI Control"  = list(mod = res_evi_control$modelo,   ts = ts_evi_control),
  "NDMI Control" = list(mod = res_ndmi_control$modelo,  ts = ts_ndmi_control)
)

tabla_final <- data.frame(
  Serie        = names(resultados),
  Orden_SARIMA = sapply(resultados, function(r) paste(arimaorder(r$mod), collapse = ",")),
  AIC          = sapply(resultados, function(r) round(r$mod$aic, 1)),
  RMSE_CV      = sapply(resultados, function(r) round(calcular_rmse_cv(r$ts), 4))
)
print(tabla_final)
write.csv(tabla_final, paste0(ruta, "tabla_comparativa_sarima.csv"), row.names = FALSE)

# Hallazgo: EVI y SAVI son consistentemente más predecibles (menor RMSE) que
# NDVI/NDMI (corrigen saturación y efecto de suelo). NDMI es el índice que MÁS
# distingue bofedal de control (mayor brecha relativa) -> más sensible a
# humedad, la variable definitoria del ecosistema de bofedal.


# =============================================================================
# 7. TENDENCIA (MANN-KENDALL) Y RELACIÓN CON CLIMA (CCF SOBRE RESIDUOS)
# =============================================================================
series_lista <- list(
  "NDVI Bofedal" = ts_ndvi_bofedal, "SAVI Bofedal" = ts_savi_bofedal,
  "EVI Bofedal"  = ts_evi_bofedal,  "NDMI Bofedal" = ts_ndmi_bofedal,
  "NDVI Control" = ts_ndvi_control, "SAVI Control" = ts_savi_control,
  "EVI Control"  = ts_evi_control,  "NDMI Control" = ts_ndmi_control
)

tabla_tendencia <- data.frame(
  Serie   = names(series_lista),
  Tau     = sapply(series_lista, function(s) round(MannKendall(s)$tau, 3)),
  p_valor = sapply(series_lista, function(s) round(MannKendall(s)$sl, 4))
)
tabla_tendencia$Tendencia <- ifelse(tabla_tendencia$p_valor < 0.05,
                                    ifelse(tabla_tendencia$Tau > 0, "Creciente (significativa)", "Decreciente (significativa)"),
                                    "Sin tendencia significativa")
print(tabla_tendencia)
write.csv(tabla_tendencia, paste0(ruta, "tabla_mann_kendall.csv"), row.names = FALSE)

# Hallazgo: NINGUNA serie muestra tendencia significativa 2019-2025. Contrasta
# con la cifra oficial INAIGEM de "pérdida del 30% de área" en la zona norte de
# Puno -> son métricas distintas: área total del ecosistema vs. vigor/humedad
# de la vegetación remanente. El bofedal remanente no muestra degradación de
# vigor en esta ventana temporal, aunque su superficie total sí se haya reducido.

# CCF sobre RESIDUOS deseasonalizados (evita el sesgo de correlacionar dos
# series igualmente estacionales, que generaría picos espurios en múltiples lags)
extraer_residuo <- function(ts_serie) stl(ts_serie, s.window = "periodic")$time.series[, "remainder"]

resid_precip       <- extraer_residuo(ts_precip)
resid_ndvi_bofedal <- extraer_residuo(ts_ndvi_bofedal)
resid_evi_bofedal  <- extraer_residuo(ts_evi_bofedal)
resid_ndmi_bofedal <- extraer_residuo(ts_ndmi_bofedal)
resid_ndvi_control <- extraer_residuo(ts_ndvi_control)

png(paste0(ruta, "ccf_precipitacion_residuos.png"), width = 1100, height = 800, res = 120)
par(mfrow = c(2,2))
ccf(resid_precip, resid_ndvi_bofedal, main = "Precip vs NDVI Bofedal (residuos)", lag.max = 6)
ccf(resid_precip, resid_evi_bofedal,  main = "Precip vs EVI Bofedal (residuos)",  lag.max = 6)
ccf(resid_precip, resid_ndmi_bofedal, main = "Precip vs NDMI Bofedal (residuos)", lag.max = 6)
ccf(resid_precip, resid_ndvi_control, main = "Precip vs NDVI Control (residuos)", lag.max = 6)
par(mfrow = c(1,1))
dev.off()

# Hallazgo: sin pico dominante tras remover estacionalidad -> el efecto de la
# precipitación opera principalmente vía el ciclo estacional anual, ya
# capturado por el componente SAR/SMA de cada SARIMA (se confirma en el paso 8).


# =============================================================================
# 8. SARIMAX (precipitación como exógena) — PRUEBA DE ROBUSTEZ
# =============================================================================
ajustar_sarimax_final <- function(serie_ts, precip_ts, mejor_lag, nombre) {
  precip_lag <- stats::lag(precip_ts, -mejor_lag)
  datos <- ts.intersect(y = serie_ts, x = precip_lag)
  
  modelo_base <- auto.arima(datos[, "y"], seasonal = TRUE, stepwise = FALSE, approximation = FALSE)
  modelo_xreg <- auto.arima(datos[, "y"], xreg = datos[, "x"], seasonal = TRUE,
                            stepwise = FALSE, approximation = FALSE)
  
  cat("\n=====", nombre, "| lag =", mejor_lag, "=====\n")
  cat("AIC sin clima:", round(modelo_base$aic, 2),
      "| AIC con clima:", round(modelo_xreg$aic, 2), "\n")
  print(summary(modelo_xreg))
  cat("Ljung-Box p (SARIMAX):", round(checkresiduals(modelo_xreg, plot = FALSE)$p.value, 4), "\n")
  list(base = modelo_base, xreg = modelo_xreg, lag = mejor_lag)
}

# Lags óptimos ya identificados por búsqueda previa (0:3) vía AIC mínimo
sarimax_ndvi <- ajustar_sarimax_final(ts_ndvi_bofedal, ts_precip, 2, "NDVI Bofedal")
sarimax_evi  <- ajustar_sarimax_final(ts_evi_bofedal,  ts_precip, 0, "EVI Bofedal")
sarimax_ndmi <- ajustar_sarimax_final(ts_ndmi_bofedal, ts_precip, 3, "NDMI Bofedal")

# Hallazgo: en los 3 casos el coeficiente de precipitación NO es significativo
# (error estándar >= coeficiente). Se confirma que el clima ya está capturado
# por el componente estacional -> SE ADOPTAN LOS MODELOS SARIMA PUROS (paso 5)
# como modelos finales del artículo, por parsimonia.


# =============================================================================
# 9. PRONÓSTICO FINAL (2026-2027)
# =============================================================================
graf_forecast <- function(modelo, nombre) {
  autoplot(forecast(modelo, h = 24)) +
    labs(title = paste0("Pronóstico 2026-2027 — ", nombre), x = NULL, y = nombre) +
    theme_minimal(base_size = 12) +
    theme(plot.title = element_text(face = "bold", size = 13))
}

panel_forecast <- (graf_forecast(modelo_ndvi_bofedal, "NDVI Bofedal") |
                     graf_forecast(res_evi_bofedal$modelo, "EVI Bofedal")) /
  (graf_forecast(res_ndmi_bofedal$modelo, "NDMI Bofedal") |
     graf_forecast(res_ndvi_control$modelo, "NDVI Control")) +
  plot_annotation(title = "Pronóstico SARIMA — Bofedales de Carabaya (2026-2027)")

ggsave(paste0(ruta, "panel_forecast_final.png"), panel_forecast, width = 13, height = 9, dpi = 300, bg = "white")


# =============================================================================
# 10. TABLA DESCRIPTIVA (Tabla 1 del artículo)
# =============================================================================
tabla_descriptiva <- serie %>%
  select(all_of(columnas_indices)) %>%
  pivot_longer(everything(), names_to = "variable", values_to = "valor") %>%
  group_by(variable) %>%
  summarise(Media = round(mean(valor), 3), DE = round(sd(valor), 3),
            Min = round(min(valor), 3), Max = round(max(valor), 3),
            CV_pct = round(100 * sd(valor)/mean(valor), 1))

print(tabla_descriptiva)
write.csv(tabla_descriptiva, paste0(ruta, "tabla_descriptiva.csv"), row.names = FALSE)


# =============================================================================
# 11. MAPA DEL ÁREA DE ESTUDIO (usa el archivo corregido, solo Carabaya)
# =============================================================================
bofedales_carabaya <- st_read(ruta_geo)
cat("Polígonos de bofedal cargados:", nrow(bofedales_carabaya), "(debe ser ~9920)\n")

provincias_puno   <- st_read(ruta_provincias)
carabaya_poligono <- provincias_puno %>% filter(PROVINCIA == "CARABAYA")

mapa_principal <- ggplot() +
  geom_sf(data = carabaya_poligono, fill = "grey95", color = "black", linewidth = 0.5) +
  geom_sf(data = bofedales_carabaya, fill = "#2E8B57", color = NA, alpha = 0.85) +
  annotation_scale(location = "bl", width_hint = 0.25) +
  annotation_north_arrow(location = "tr", which_north = "true",
                         style = north_arrow_fancy_orienteering()) +
  labs(title = "Área de estudio: Bofedales de la provincia de Carabaya",
       subtitle = "Departamento de Puno, Perú — Fuente: INAIGEM (2023)",
       x = "Longitud", y = "Latitud") +
  theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold", size = 13),
        plot.subtitle = element_text(size = 9, color = "grey40"),
        panel.grid = element_line(color = "grey90", linewidth = 0.2))

mapa_contexto <- ggplot() +
  geom_sf(data = provincias_puno, fill = "grey90", color = "white", linewidth = 0.3) +
  geom_sf(data = carabaya_poligono, fill = "#B22222", color = "black", linewidth = 0.3) +
  theme_void() +
  theme(panel.background = element_rect(fill = "white", color = "black", linewidth = 0.5))

mapa_final <- mapa_principal +
  inset_element(mapa_contexto, left = 0.68, bottom = 0.68, right = 0.98, top = 0.98)

ggsave(paste0(ruta, "mapa_area_estudio.png"), mapa_final, width = 10, height = 9, dpi = 300, bg = "white")

serie_larga %>%
  ggplot(aes(x = indice, y = valor, fill = zona)) +
  geom_boxplot(alpha = 0.85, outlier.size = 0.8) +
  scale_fill_manual(values = c(Bofedal = "#2E8B57", Control = "#D2691E")) +
  labs(title = "Comparación Bofedal vs. Control por índice (2019-2025)",
       x = NULL, y = "Valor del índice", fill = NULL) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "top")
ggsave(paste0(ruta, "boxplot_bofedal_vs_control.png"), width = 9, height = 6, dpi = 300, bg = "white")



# =============================================================================
# FIN — Archivos generados en: ruta
#  serie_limpia_carabaya_2019_2025.csv | panel_series_temporales.png
#  stl_[ndvi|evi|ndmi|savi]_bofedal.png | residuos_ndvi_bofedal.png
#  tabla_comparativa_sarima.csv | tabla_mann_kendall.csv | tabla_descriptiva.csv
#  ccf_precipitacion_residuos.png | panel_forecast_final.png | mapa_area_estudio.png
# =============================================================================
