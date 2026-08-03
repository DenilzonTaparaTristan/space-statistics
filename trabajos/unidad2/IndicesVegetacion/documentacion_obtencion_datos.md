# Obtención de datos — Variabilidad espacial de índices de vegetación en Puno

## 1. Contexto y justificación de las fuentes

El artículo de referencia (Lourenço & Landim, UNESP) trabaja con NDVI derivado de
imágenes Landsat sobre la Baixada Santista (Brasil), combinado con puntos de
muestreo de campo para aplicar kriging indicativo. Para replicar esta
metodología en el departamento de Puno no se contaba con muestreo de campo
propio, por lo que se optó por una estrategia de **datos abiertos
satelitales**, sustituyendo el trabajo de campo por un muestreo aleatorio
extraído directamente de imágenes de sensores remotos mediante Google Earth
Engine (GEE). Esta decisión permite mantener la lógica geoestadística del
paper (puntos con coordenadas + valor del índice → semivariograma → kriging)
sin requerir salidas de campo, a costa de no contar con validación in situ.

Se trabajaron dos ejes de información:

1. **Límites administrativos** del área de estudio (las 13 provincias de Puno).
2. **Índices de vegetación e insumos ambientales** (NDVI, SAVI, EVI, NDMI,
   altitud, precipitación) extraídos por sensoramiento remoto.

---

## 2. Límites administrativos de las provincias de Puno

### 2.1 Fuente
Se utilizó el shapefile oficial de **Límite Distrital, INEI 2025**, obtenido a
través del portal GeoGPS Perú, que centraliza las capas geográficas oficiales
del Instituto Nacional de Estadística e Informática (INEI) y del Instituto
Geográfico Nacional (IGN). Se eligió la capa distrital 2025 por ser, al
momento de la consulta, la versión con fecha de actualización más reciente
disponible entre las opciones ofrecidas (INEI 2007, IGN 2017, INEI 2017, INEI
2023 e INEI 2025), priorizando vigencia sobre otras versiones históricas.

### 2.2 Proceso de filtrado y disolución (QGIS)
El archivo descargado corresponde a la totalidad de distritos del Perú, por lo
que fue necesario un proceso de acotamiento geográfico:

1. **Carga en QGIS** del shapefile completo (`Limite Distrital INEI 2025
   CPV.shp`), verificando que los archivos complementarios (`.dbf`, `.shx`,
   `.prj`, `.cpg`) se mantuvieran en la misma carpeta.
2. **Selección por atributos**, filtrando únicamente los distritos cuyo campo
   `DEPARTAMEN` correspondiera a "PUNO", mediante la herramienta *Seleccionar
   por expresión* (`"DEPARTAMEN" = 'PUNO'`).
3. **Exportación** de la selección como una capa independiente
   (`distritos_puno.shp`), limitada exclusivamente al departamento de interés.
4. **Disolución (dissolve)** de los distritos agrupándolos por el campo
   `PROVINCIA`, con el fin de obtener un polígono por cada una de las 13
   provincias del departamento (Puno, San Román, Azángaro, Carabaya,
   Chucuito, El Collao, Huancané, Lampa, Melgar, Moho, Sandia, San Antonio de
   Putina y Yunguyo), en lugar de mantener la resolución distrital original.
5. **Exportación final** en formato GeoPackage (`provincias_puno.gpkg`), y
   posteriormente también en formato Shapefile, para compatibilidad con
   distintas herramientas de análisis (R, Google Earth Engine).

### 2.3 Verificación
Se confirmó la integridad del resultado revisando la tabla de atributos de la
capa disuelta, corroborando la presencia de las 13 provincias esperadas y
visualizando el polígono resultante sobre el mapa base de QGIS.

---

## 3. Índices de vegetación e insumos satelitales (Google Earth Engine)

### 3.1 Justificación de la plataforma
Se utilizó **Google Earth Engine** en lugar de la descarga manual de escenas
Landsat (como en el paper original) por tres razones: (i) permite calcular
índices espectrales directamente sobre la nube sin necesidad de procesar
imágenes localmente; (ii) facilita el filtrado automático de nubosidad sobre
grandes colecciones temporales; y (iii) integra en un mismo entorno de
programación (JavaScript) tanto la extracción de bandas espectrales como el
muestreo de puntos y la exportación tabular.

### 3.2 Carga del área de estudio
El polígono de provincias de Puno (`provincias_puno.gpkg`), generado en el
paso anterior, fue subido como *Asset* privado dentro del proyecto de Google
Earth Engine (`projects/project-b77644b9-c9ce-4a03-acc/assets/provincias_puno2`),
sirviendo como máscara espacial (`clip`) para todas las operaciones
posteriores.

### 3.3 Selección de la colección satelital
Se utilizó la colección **Sentinel-2 Surface Reflectance Harmonized**
(`COPERNICUS/S2_SR_HARMONIZED`), en lugar de Landsat, debido a su mayor
resolución espacial (10 m frente a los 30 m de Landsat), lo cual resulta
relevante dada la heterogeneidad del paisaje altiplánico y la presencia de
parcelas agrícolas de tamaño reducido.

### 3.4 Definición de las épocas de análisis
Con el fin de capturar la variabilidad estacional de la vegetación —un
aspecto no abordado en el paper original pero relevante para el contexto
altiplánico de Puno—, se definieron dos ventanas temporales:

| Época | Rango de fechas | Filtro de nubosidad |
|---|---|---|
| Seca | 01/05/2024 – 31/08/2024 | `CLOUDY_PIXEL_PERCENTAGE` < 10% |
| Húmeda | 01/12/2023 – 31/03/2024 | `CLOUDY_PIXEL_PERCENTAGE` < 20% |

El umbral de nubosidad se flexibilizó para la época húmeda debido a la mayor
frecuencia de cobertura nubosa característica de la temporada de lluvias en
la región andina, lo cual redujo el número de imágenes disponibles y, en
consecuencia, el número final de puntos válidos para esa época.

Para cada ventana temporal se generó un **compuesto por mediana** (`.median()`)
de todas las imágenes disponibles que cumplieran el filtro de nubosidad,
reduciendo así el ruido asociado a nubes residuales o sombras puntuales.

### 3.5 Cálculo de los índices de vegetación
A partir de las bandas espectrales de Sentinel-2 (B2 = azul, B4 = rojo, B8 =
infrarrojo cercano, B11 = infrarrojo de onda corta), se calcularon los
siguientes cuatro índices, ampliando el enfoque del paper original (que
trabaja únicamente con NDVI):

- **NDVI** = (NIR − RED) / (NIR + RED)
- **SAVI** = (1 + L)·(NIR − RED) / (NIR + RED + L), con L = 0.5
- **EVI**  = 2.5·(NIR − RED) / (NIR + 6·RED − 7.5·BLUE + 1)
- **NDMI** = (NIR − SWIR) / (NIR + SWIR)

### 3.6 Variables ambientales complementarias
Para enriquecer el análisis con contexto ambiental, se incorporaron dos
variables adicionales, muestreadas en los mismos puntos que los índices de
vegetación:

- **Altitud**: modelo de elevación digital SRTM a 30 m de resolución
  (`USGS/SRTMGL1_003`).
- **Precipitación acumulada**: suma diaria de precipitación estimada por el
  producto CHIRPS (`UCSB-CHG/CHIRPS/DAILY`), acumulada sobre el rango de
  fechas correspondiente a cada época.

### 3.7 Diseño del muestreo espacial
Dado que no se contaba con puntos de muestreo de campo, se generó una
**grilla de 500 puntos aleatorios** dentro del polígono de Puno
(`ee.FeatureCollection.randomPoints`), fijando una semilla (`seed = 42`) para
garantizar la reproducibilidad del muestreo. Es importante señalar que **se
utilizó la misma grilla de puntos para ambas épocas del año**, con el
propósito de que las comparaciones estacionales reflejaran variación
temporal real y no diferencias atribuibles a un cambio en la ubicación de los
puntos muestreados.

En cada punto de la grilla se extrajeron, mediante `sampleRegions()` a una
escala de 10 metros, los valores de los cuatro índices de vegetación junto
con la altitud y la precipitación acumulada correspondientes.

### 3.8 Exportación
Los resultados del muestreo fueron exportados como archivos CSV hacia Google
Drive (`muestras_indices_puno_seca.csv` y `muestras_indices_puno_humeda.csv`),
cada uno conteniendo las columnas: `NDVI`, `SAVI`, `EVI`, `NDMI`, `altitud`,
`precipitacion`, y un campo `.geo` con las coordenadas del punto en formato
GeoJSON, del cual se extrajeron posteriormente la longitud y latitud para su
uso en el análisis geoestadístico en R.

---

## 4. Resumen del volumen final de datos

| Época | Puntos exportados desde GEE | Puntos válidos tras limpieza de outliers |
|---|---|---|
| Seca | 500 | 500 |
| Húmeda | 500 | 334 |

La reducción observada en la época húmeda se explica por dos factores: (i) el
mayor umbral de nubosidad permitido (20% frente a 10%) implica una mayor
probabilidad de píxeles contaminados por nubes residuales en algunos puntos
de muestreo, y (ii) el proceso de limpieza posterior en R, que descartó
registros con valores fuera del rango físicamente posible para cada índice
(en particular en EVI, cuya fórmula puede generar valores extremos cuando el
denominador se aproxima a cero).

---

## 5. Herramientas empleadas en esta etapa

| Herramienta | Uso específico |
|---|---|
| GeoGPS Perú | Repositorio de descarga de límites administrativos oficiales |
| QGIS | Filtrado por departamento y disolución por provincia |
| Google Earth Engine (JavaScript) | Cálculo de índices espectrales, muestreo aleatorio y exportación |
| Sentinel-2 SR Harmonized | Fuente satelital de bandas espectrales (10 m) |
| SRTM (USGS) | Modelo de elevación digital (altitud) |
| CHIRPS (UCSB-CHG) | Estimación de precipitación diaria |
| Google Drive | Almacenamiento intermedio de los CSV exportados |
