#Estadistica Espacial
# NOmbre: Denilzon Robinho Tapara Tristan "X" "B"
# ANÁLISIS ESPACIAL COMPLETO — CULTIVOS COSECHADOS PERÚ
# Dataset: 229CDE.csv
# Variables: Producción (P229D), Venta (P229E_1), Consumo (P229E_2)
#            Cultivo (P229C_NOM), Departamento, Provincia, Distrito

library(data.table)
library(dplyr)
library(stringr)
library(stringi)
library(ggplot2)
library(sf)
library(geodata)
library(scales)      # formatos de números en gráficos
library(knitr)       # tablas en consola
library(gridExtra)   # combinar múltiples gráficos

### 1. CARGAR DE DATOS


data <- fread(
  "D:/UNA/A/10/estadistica espacial/229CDE.csv",
  colClasses = "character"
)
setDT(data)

# 2. FUNCIÓN DE LIMPIEZA GEOGRÁFICA

clean_geo <- function(x) {
  x <- iconv(x, from = "UTF-8", to = "ASCII//TRANSLIT", sub = "")
  x <- toupper(trimws(x))
  x <- gsub("[^A-Z ]", "", x)
  x <- trimws(x)
  return(x)
}

# ============================================================
# 3. LIMPIEZA GEOGRÁFICA

data[, DEPARTAMENTO := clean_geo(NOMBREDD)]
data[, PROVINCIA    := clean_geo(NOMBREPV)]
data[, DISTRITO     := clean_geo(NOMBREDI)]
data <- data[!is.na(DEPARTAMENTO) & DEPARTAMENTO != ""]

data[, DEPARTAMENTO := fcase(
  DEPARTAMENTO %like% "AMAZ",           "AMAZONAS",
  DEPARTAMENTO %like% "ANC",            "ANCASH",
  DEPARTAMENTO %like% "APUR",           "APURIMAC",
  DEPARTAMENTO %like% "AREQ",           "AREQUIPA",
  DEPARTAMENTO %like% "AYAC",           "AYACUCHO",
  DEPARTAMENTO %like% "CAJ",            "CAJAMARCA",
  DEPARTAMENTO %like% "^CALL",          "CALLAO",
  DEPARTAMENTO %like% "CUS",            "CUSCO",
  DEPARTAMENTO %like% "HUANCAV",        "HUANCAVELICA",
  DEPARTAMENTO %like% "HUANU",          "HUANUCO",
  DEPARTAMENTO %like% "^ICA",           "ICA",
  DEPARTAMENTO %like% "JUN",            "JUNIN",
  DEPARTAMENTO %like% "LIB",            "LA LIBERTAD",
  DEPARTAMENTO %like% "LAMB",           "LAMBAYEQUE",
  DEPARTAMENTO %like% "^LIMA",          "LIMA",
  DEPARTAMENTO %like% "LORE",           "LORETO",
  DEPARTAMENTO %like% "MADRE",          "MADRE DE DIOS",
  DEPARTAMENTO %like% "MOQ",            "MOQUEGUA",
  DEPARTAMENTO %like% "^PASC",          "PASCO",
  DEPARTAMENTO %like% "^PIUR",          "PIURA",
  DEPARTAMENTO %like% "^PUNO",          "PUNO",
  DEPARTAMENTO %like% "SAN M",          "SAN MARTIN",
  DEPARTAMENTO %like% "^TACNA",         "TACNA",
  DEPARTAMENTO %like% "TUMB",           "TUMBES",
  DEPARTAMENTO %like% "UCAY",           "UCAYALI",
  default = DEPARTAMENTO
)]

# ========================================
# 4. VARIABLES NUMÉRICAS

cols_num <- c(
  "P229D_CANT_ENT", "P229D_CANT_DEC",
  "P229E_1_CANT_ENT", "P229E_1_CANT_DEC",
  "P229E_2_ENT", "P229E_2_DEC",
  "P229E_3_ENT", "P229E_3_DEC"
)
for (col in cols_num) {
  data[, (col) := as.numeric(ifelse(get(col) == "" | is.na(get(col)), NA, get(col)))]
}

data[, PRODUCCION := P229D_CANT_ENT    + (P229D_CANT_DEC / 10)]
data[, VENTA      := P229E_1_CANT_ENT + (P229E_1_CANT_DEC / 10)]
data[, CONSUMO    := P229E_2_ENT      + (P229E_2_DEC / 10)]
data[, OTROS      := P229E_3_ENT      + (P229E_3_DEC / 10)]
data[, CULTIVO    := toupper(trimws(P229C_NOM))]
data[CULTIVO == "" | is.na(CULTIVO), CULTIVO := NA]

# ======================================
# 5. FILTRADO: SOLO REGISTROS VÁLIDOS

data_limpia <- data[!is.na(PRODUCCION) & PRODUCCION > 0 & !is.na(DEPARTAMENTO)]

# ===================
# 6. RESÚMENES BASE

# 6.1 Por Departamento
dep <- data_limpia[, .(
  PROD_TOTAL   = sum(PRODUCCION,  na.rm = TRUE),
  PROD_PROM    = mean(PRODUCCION, na.rm = TRUE),
  VENTA_TOTAL  = sum(VENTA,       na.rm = TRUE),
  VENTA_PROM   = mean(VENTA,      na.rm = TRUE),
  CONSUMO_TOTAL= sum(CONSUMO,     na.rm = TRUE),
  CONSUMO_PROM = mean(CONSUMO,    na.rm = TRUE),
  N_REGISTROS  = .N
), by = DEPARTAMENTO][order(-PROD_TOTAL)]

# Porcentaje del total nacional
dep[, PCT_NACIONAL := round(PROD_TOTAL / sum(PROD_TOTAL) * 100, 2)]

# 6.2 Por Departamento + Cultivo (todos los cultivos)
dep_cult <- data_limpia[!is.na(CULTIVO), .(
  PROD_TOTAL  = sum(PRODUCCION,  na.rm = TRUE),
  PROD_PROM   = mean(PRODUCCION, na.rm = TRUE),
  VENTA_TOTAL = sum(VENTA,       na.rm = TRUE),
  N_REGISTROS = .N
), by = .(DEPARTAMENTO, CULTIVO)][order(DEPARTAMENTO, -PROD_TOTAL)]

# 6.3 Cultivo dominante por departamento 
cultivo_dom <- dep_cult[, .SD[1], by = DEPARTAMENTO]

# 6.4 Por Provincia
prov <- data_limpia[!is.na(PROVINCIA), .(
  PROD_TOTAL  = sum(PRODUCCION,  na.rm = TRUE),
  PROD_PROM   = mean(PRODUCCION, na.rm = TRUE),
  VENTA_TOTAL = sum(VENTA,       na.rm = TRUE),
  N_REGISTROS = .N
), by = .(DEPARTAMENTO, PROVINCIA)][order(DEPARTAMENTO, -PROD_TOTAL)]

# 6.5 Por Distrito 
dist <- data_limpia[!is.na(DISTRITO), .(
  PROD_TOTAL  = sum(PRODUCCION,  na.rm = TRUE),
  PROD_PROM   = mean(PRODUCCION, na.rm = TRUE),
  VENTA_TOTAL = sum(VENTA,       na.rm = TRUE),
  N_REGISTROS = .N
), by = .(DEPARTAMENTO, PROVINCIA, DISTRITO)][order(-PROD_TOTAL)]

# 6.6 Top 3 distritos por departamento 
top3_dist <- dist[, .SD[1:min(.N, 3)], by = DEPARTAMENTO]

# --- 6.7 Top 3 cultivos por departamento 
top3_cult <- dep_cult[, .SD[1:min(.N, 3)], by = DEPARTAMENTO]

# ===================================
# 7. TABLAS IMPRESAS EN CONSOLA


print(dep[, .(DEPARTAMENTO, PROD_TOTAL = round(PROD_TOTAL,1),
              PROD_PROM = round(PROD_PROM,1),
              VENTA_TOTAL = round(VENTA_TOTAL,1),
              CONSUMO_TOTAL = round(CONSUMO_TOTAL,1),
              N_REGISTROS, PCT_NACIONAL)])


print(dist[1:20, .(DEPARTAMENTO, PROVINCIA, DISTRITO,
                   PROD_TOTAL = round(PROD_TOTAL,1),
                   PROD_PROM  = round(PROD_PROM,1),
                   N_REGISTROS)])


print(top3_dist[, .(DEPARTAMENTO, DISTRITO,
                    PROD_TOTAL = round(PROD_TOTAL,1),
                    PROD_PROM  = round(PROD_PROM,1),
                    N_REGISTROS)])

print(top3_cult[, .(DEPARTAMENTO, CULTIVO,
                    PROD_TOTAL  = round(PROD_TOTAL,1),
                    PROD_PROM   = round(PROD_PROM,1),
                    VENTA_TOTAL = round(VENTA_TOTAL,1),
                    N_REGISTROS)])

print(cultivo_dom[, .(DEPARTAMENTO, CULTIVO,
                      PROD_TOTAL = round(PROD_TOTAL,1),
                      N_REGISTROS)])

# =======================
# 8. SHAPEFILE Y MERGE

peru_raw <- geodata::gadm(country = "PER", level = 1, path = tempdir())
peru     <- st_as_sf(peru_raw)
peru[, "DEPARTAMENTO"] <- clean_geo(peru$NAME_1)

mapa_base    <- merge(peru, dep,         by = "DEPARTAMENTO", all.x = TRUE)
mapa_cultivo <- merge(mapa_base, cultivo_dom[, .(DEPARTAMENTO, CULTIVO)],
                      by = "DEPARTAMENTO", all.x = TRUE)

centroides    <- st_centroid(mapa_cultivo)
centroides_df <- cbind(
  as.data.frame(centroides["DEPARTAMENTO"]),
  st_coordinates(centroides)
)

cat("\nDiferencias shapefile vs datos:\n")
print(setdiff(peru$DEPARTAMENTO, dep$DEPARTAMENTO))

# ======================
# 9. TEMA UNIFICADO

tema_mapa <- theme(
  plot.title    = element_text(size = 13, face = "bold", hjust = 0.5, margin = margin(b=6)),
  plot.subtitle = element_text(size = 9,  hjust = 0.5, color = "grey40", margin = margin(b=10)),
  plot.caption  = element_text(size = 7,  color = "grey50", hjust = 1),
  legend.position  = "right",
  legend.title     = element_text(size = 8, face = "bold"),
  legend.text      = element_text(size = 7),
  legend.key.size  = unit(0.5, "cm"),
  panel.background = element_rect(fill = "#EAF4FB", color = NA),
  plot.background  = element_rect(fill = "white",   color = NA),
  panel.grid       = element_blank(),
  axis.text        = element_blank(),
  axis.ticks       = element_blank(),
  plot.margin      = margin(10, 10, 10, 10)
)

# =============================
# 10. MAPAS COROPLÉTICOS
# ================================
# Helper: merge centroides con columna de datos
merge_cent <- function(col) {
  merge(centroides_df,
        as.data.frame(mapa_cultivo)[, c("DEPARTAMENTO", col)],
        by = "DEPARTAMENTO")
}

#  MAPA 1: Producción Total
ggplot(mapa_cultivo) +
  geom_sf(aes(fill = PROD_TOTAL), color = "white", linewidth = 0.3) +
  geom_text(data = merge_cent("PROD_TOTAL"),
            aes(x=X, y=Y, label=paste0(DEPARTAMENTO,"\n", round(PROD_TOTAL))),
            size=1.6, fontface="bold", lineheight=0.85) +
  scale_fill_viridis_c(option="plasma", na.value="grey80",
                       labels=comma, name="Producción\ntotal") +
  coord_sf(expand=FALSE) +
  labs(title="Producción Total de Cultivos Cosechados",
       subtitle="Censo Agropecuario — Perú",
       caption="Fuente: Censo Nacional Agropecuario | Variable P229D") +
  tema_mapa

#MAPA 2: 
ggplot(mapa_cultivo) +
  geom_sf(aes(fill = PROD_PROM), color = "white", linewidth = 0.3) +
  geom_text(data = merge_cent("PROD_PROM"),
            aes(x=X, y=Y, label=paste0(DEPARTAMENTO,"\n", round(PROD_PROM,1))),
            size=1.6, fontface="bold", lineheight=0.85) +
  scale_fill_viridis_c(option="viridis", na.value="grey80",
                       labels=comma, name="Producción\npromedio") +
  coord_sf(expand=FALSE) +
  labs(title="Producción Promedio de Cultivos Cosechados",
       subtitle="Censo Agropecuario — Perú",
       caption="Fuente: Censo Nacional Agropecuario | Variable P229D") +
  tema_mapa

# MAPA 3
ggplot(mapa_cultivo) +
  geom_sf(aes(fill = VENTA_TOTAL), color = "white", linewidth = 0.3) +
  geom_text(data = merge_cent("VENTA_TOTAL"),
            aes(x=X, y=Y, label=paste0(DEPARTAMENTO,"\n", round(VENTA_TOTAL))),
            size=1.6, fontface="bold", lineheight=0.85) +
  scale_fill_viridis_c(option="magma", na.value="grey80",
                       labels=comma, name="Venta\ntotal") +
  coord_sf(expand=FALSE) +
  labs(title="Venta Total de Cultivos Cosechados por Departamento",
       subtitle="Censo Agropecuario — Perú",
       caption="Fuente: Censo Nacional Agropecuario | Variable P229E_1") +
  tema_mapa

# MAPA 4
ggplot(mapa_cultivo) +
  geom_sf(aes(fill = CONSUMO_TOTAL), color = "white", linewidth = 0.3) +
  geom_text(data = merge_cent("CONSUMO_TOTAL"),
            aes(x=X, y=Y, label=paste0(DEPARTAMENTO,"\n", round(CONSUMO_TOTAL))),
            size=1.6, fontface="bold", lineheight=0.85) +
  scale_fill_viridis_c(option="cividis", na.value="grey80",
                       labels=comma, name="Consumo\ntotal") +
  coord_sf(expand=FALSE) +
  labs(title="Consumo Total de Cultivos Cosechados por Departamento",
       subtitle="Censo Agropecuario — Perú",
       caption="Fuente: Censo Nacional Agropecuario | Variable P229E_2") +
  tema_mapa

#MAPA 5
ggplot(mapa_cultivo) +
  geom_sf(aes(fill = CULTIVO), color = "white", linewidth = 0.3) +
  geom_text(data = merge_cent("CULTIVO"),
            aes(x=X, y=Y, label=DEPARTAMENTO),
            size=1.6, fontface="bold") +
  scale_fill_brewer(palette="Set3", na.value="grey80", name="Cultivo\nDominante") +
  coord_sf(expand=FALSE) +
  labs(title="Cultivo Cosechado Dominante por Departamento",
       subtitle="Censo Agropecuario — Perú",
       caption="Fuente: Censo Nacional Agropecuario | Variable P229C") +
  tema_mapa
ggsave("mapa_05_cultivo_dominante.png", width=8, height=9, dpi=200, bg="white")

#MAPA 6
ggplot(mapa_cultivo) +
  geom_sf(aes(fill = N_REGISTROS), color = "white", linewidth = 0.3) +
  geom_text(data = merge_cent("N_REGISTROS"),
            aes(x=X, y=Y, label=paste0(DEPARTAMENTO,"\n", N_REGISTROS)),
            size=1.6, fontface="bold", lineheight=0.85) +
  scale_fill_distiller(palette="YlOrRd", direction=1, na.value="grey80",
                       labels=comma, name="N° de\nregistros") +
  coord_sf(expand=FALSE) +
  labs(title="Número de Unidades Agropecuarias con Cultivos Cosechados",
       subtitle="Censo Agropecuario — Perú",
       caption="Fuente: Censo Nacional Agropecuario") +
  tema_mapa

# ==================================================
# 11. GRÁFICOS DE BARRAS Y COMPARACIONES
# ========================================

#GRÁFICO 1
ggplot(dep, aes(x=reorder(DEPARTAMENTO, PROD_TOTAL),
                y=PROD_TOTAL, fill=PROD_TOTAL)) +
  geom_col(show.legend=FALSE) +
  geom_text(aes(label=comma(round(PROD_TOTAL))), hjust=-0.1, size=2.4) +
  scale_fill_viridis_c(option="plasma") +
  scale_y_continuous(labels=comma) +
  coord_flip(clip="off") +
  expand_limits(y=max(dep$PROD_TOTAL, na.rm=TRUE)*1.18) +
  theme_minimal(base_size=10) +
  theme(plot.title=element_text(face="bold", hjust=0.5),
        axis.text.y=element_text(size=7),
        plot.margin=margin(10,30,10,10)) +
  labs(title="Ranking: Producción Total de Cultivos Cosechados",
       x=NULL, y="Producción total",
       caption="Fuente: Censo Nacional Agropecuario")

#GRÁFICO 2
dep_long <- melt(dep[, .(DEPARTAMENTO, PROD_TOTAL, VENTA_TOTAL, CONSUMO_TOTAL)],
                 id.vars="DEPARTAMENTO",
                 variable.name="VARIABLE",
                 value.name="VALOR")
dep_long[, VARIABLE := fcase(
  VARIABLE == "PROD_TOTAL",    "Producción",
  VARIABLE == "VENTA_TOTAL",   "Venta",
  VARIABLE == "CONSUMO_TOTAL", "Consumo"
)]

ggplot(dep_long, aes(x=reorder(DEPARTAMENTO, VALOR), y=VALOR, fill=VARIABLE)) +
  geom_col(position="dodge") +
  scale_fill_manual(values=c("Producción"="#1B4F72", "Venta"="#E67E22", "Consumo"="#1E8449"),
                    name="Variable") +
  scale_y_continuous(labels=comma) +
  coord_flip() +
  theme_minimal(base_size=9) +
  theme(plot.title=element_text(face="bold", hjust=0.5),
        axis.text.y=element_text(size=6.5),
        legend.position="top",
        plot.margin=margin(10,15,10,10)) +
  labs(title="Comparación: Producción, Venta y Consumo por Departamento",
       x=NULL, y="Cantidad total",
       caption="Fuente: Censo Nacional Agropecuario")

#GRÁFICO 3
ggplot(dep, aes(x=reorder(DEPARTAMENTO, PCT_NACIONAL),
                y=PCT_NACIONAL, fill=PCT_NACIONAL)) +
  geom_col(show.legend=FALSE) +
  geom_text(aes(label=paste0(PCT_NACIONAL, "%")), hjust=-0.1, size=2.4) +
  scale_fill_viridis_c(option="inferno") +
  coord_flip(clip="off") +
  expand_limits(y=max(dep$PCT_NACIONAL)*1.15) +
  theme_minimal(base_size=10) +
  theme(plot.title=element_text(face="bold", hjust=0.5),
        axis.text.y=element_text(size=7),
        plot.margin=margin(10,25,10,10)) +
  labs(title="Participación (%) en la Producción Nacional por Departamento",
       x=NULL, y="% del total nacional",
       caption="Fuente: Censo Nacional Agropecuario")

# GRÁFICO 4
top10 <- data_limpia[!is.na(CULTIVO),
                     .(PROD_TOTAL=sum(PRODUCCION,na.rm=TRUE),
                       N_DEP=uniqueN(DEPARTAMENTO),
                       N_REG=.N), by=CULTIVO
][order(-PROD_TOTAL)][1:10]

ggplot(top10, aes(x=reorder(CULTIVO, PROD_TOTAL),
                  y=PROD_TOTAL, fill=PROD_TOTAL)) +
  geom_col(show.legend=FALSE) +
  geom_text(aes(label=comma(round(PROD_TOTAL))), hjust=-0.1, size=2.6) +
  scale_fill_viridis_c(option="viridis") +
  scale_y_continuous(labels=comma) +
  coord_flip(clip="off") +
  expand_limits(y=max(top10$PROD_TOTAL)*1.18) +
  theme_minimal(base_size=10) +
  theme(plot.title=element_text(face="bold", hjust=0.5, size=11),
        axis.text.y=element_text(size=8),
        plot.margin=margin(10,30,10,10)) +
  labs(title="Top 10 Cultivos Cosechados por Producción Total (Nacional)",
       x=NULL, y="Producción total",
       caption="Fuente: Censo Nacional Agropecuario")

#GRÁFICO 5
ggplot(dist[1:20], aes(x=reorder(paste0(DISTRITO,"\n(",DEPARTAMENTO,")"), PROD_TOTAL),
                       y=PROD_TOTAL, fill=DEPARTAMENTO)) +
  geom_col(show.legend=TRUE) +
  geom_text(aes(label=comma(round(PROD_TOTAL))), hjust=-0.1, size=2.2) +
  scale_y_continuous(labels=comma) +
  coord_flip(clip="off") +
  expand_limits(y=max(dist$PROD_TOTAL[1:20], na.rm=TRUE)*1.22) +
  theme_minimal(base_size=9) +
  theme(plot.title=element_text(face="bold", hjust=0.5, size=10),
        axis.text.y=element_text(size=6.5),
        legend.position="right",
        legend.text=element_text(size=6),
        legend.title=element_text(size=7),
        plot.margin=margin(10,30,10,10)) +
  labs(title="Top 20 Distritos con Mayor Producción de Cultivos Cosechados",
       x=NULL, y="Producción total",
       caption="Fuente: Censo Nacional Agropecuario")

#GRÁFICO 6:
ggplot(top3_cult,
       aes(x=reorder(CULTIVO, PROD_TOTAL), y=PROD_TOTAL, fill=CULTIVO)) +
  geom_col(show.legend=FALSE) +
  geom_text(aes(label=round(PROD_TOTAL)), hjust=-0.1, size=2.0) +
  scale_y_continuous(labels=comma) +
  coord_flip(clip="off") +
  facet_wrap(~DEPARTAMENTO, scales="free", ncol=5) +
  theme_minimal(base_size=7) +
  theme(plot.title=element_text(face="bold", hjust=0.5, size=11),
        strip.text=element_text(size=6, face="bold"),
        axis.text.y=element_text(size=5),
        axis.text.x=element_blank(),
        plot.margin=margin(10,10,10,10)) +
  labs(title="Top 3 Cultivos por Departamento — Producción Total",
       x=NULL, y=NULL,
       caption="Fuente: Censo Nacional Agropecuario")


#GRÁFICO 7
ggplot(top3_dist,
       aes(x=reorder(DISTRITO, PROD_TOTAL), y=PROD_TOTAL, fill=PROD_TOTAL)) +
  geom_col(show.legend=FALSE) +
  geom_text(aes(label=round(PROD_TOTAL)), hjust=-0.1, size=2.0) +
  scale_fill_viridis_c(option="plasma") +
  scale_y_continuous(labels=comma) +
  coord_flip(clip="off") +
  facet_wrap(~DEPARTAMENTO, scales="free", ncol=5) +
  theme_minimal(base_size=7) +
  theme(plot.title=element_text(face="bold", hjust=0.5, size=11),
        strip.text=element_text(size=6, face="bold"),
        axis.text.y=element_text(size=5),
        axis.text.x=element_blank(),
        plot.margin=margin(10,10,10,10)) +
  labs(title="Top 3 Distritos Más Productivos por Departamento",
       x=NULL, y=NULL,
       caption="Fuente: Censo Nacional Agropecuario")

#GRÁFICO 8
comp <- merge(dep, cultivo_dom[, .(DEPARTAMENTO, CULTIVO)], by="DEPARTAMENTO")

ggplot(comp, aes(x=PROD_TOTAL, y=VENTA_TOTAL,
                 color=CULTIVO, size=N_REGISTROS)) +
  geom_point(alpha=0.8) +
  geom_text(aes(label=DEPARTAMENTO), size=2.5, vjust=-1.1, color="black") +
  scale_x_continuous(labels=comma) +
  scale_y_continuous(labels=comma) +
  scale_size_continuous(range=c(3,10), name="N° registros") +
  theme_minimal(base_size=10) +
  theme(plot.title=element_text(face="bold", hjust=0.5),
        legend.position="right",
        legend.text=element_text(size=7)) +
  labs(title="Relación Producción vs Venta por Departamento",
       subtitle="Tamaño del punto = número de registros | Color = cultivo dominante",
       x="Producción total", y="Venta total", color="Cultivo\ndominante",
       caption="Fuente: Censo Nacional Agropecuario")

#GRÁFICO 9
dep[, TASA_VENTA := round(VENTA_TOTAL / PROD_TOTAL * 100, 1)]

ggplot(dep, aes(x=reorder(DEPARTAMENTO, TASA_VENTA),
                y=TASA_VENTA, fill=TASA_VENTA)) +
  geom_col(show.legend=FALSE) +
  geom_text(aes(label=paste0(TASA_VENTA,"%")), hjust=-0.1, size=2.4) +
  scale_fill_distiller(palette="RdYlGn", direction=1) +
  coord_flip(clip="off") +
  expand_limits(y=max(dep$TASA_VENTA, na.rm=TRUE)*1.18) +
  theme_minimal(base_size=10) +
  theme(plot.title=element_text(face="bold", hjust=0.5),
        axis.text.y=element_text(size=7),
        plot.margin=margin(10,25,10,10)) +
  labs(title="Tasa de Comercialización: Venta / Producción (%) por Departamento",
       subtitle="Mayor % = mayor orientación al mercado",
       x=NULL, y="% vendido sobre producción total",
       caption="Fuente: Censo Nacional Agropecuario")

# GRÁFICO 10
n_cultivos <- data_limpia[!is.na(CULTIVO),
                          .(N_CULTIVOS=uniqueN(CULTIVO)), by=DEPARTAMENTO
][order(-N_CULTIVOS)]

ggplot(n_cultivos, aes(x=reorder(DEPARTAMENTO, N_CULTIVOS),
                       y=N_CULTIVOS, fill=N_CULTIVOS)) +
  geom_col(show.legend=FALSE) +
  geom_text(aes(label=N_CULTIVOS), hjust=-0.2, size=2.8) +
  scale_fill_viridis_c(option="turbo") +
  coord_flip(clip="off") +
  expand_limits(y=max(n_cultivos$N_CULTIVOS)*1.12) +
  theme_minimal(base_size=10) +
  theme(plot.title=element_text(face="bold", hjust=0.5),
        axis.text.y=element_text(size=7),
        plot.margin=margin(10,20,10,10)) +
  labs(title="Diversidad de Cultivos Cosechados por Departamento",
       subtitle="Número de especies/cultivos distintos registrados",
       x=NULL, y="N° de cultivos distintos",
       caption="Fuente: Censo Nacional Agropecuario")

####################################