/* ============================================================
   app.js — Space Statistics v3
   ============================================================

   ══ PROBLEMA DE ARCHIVOS — EXPLICACIÓN DEFINITIVA ══════════

   GitHub Pages NO puede servir archivos que solo existen
   en tu computadora (D:\UNA\...). Para que funcionen:

   1. Abre Git Bash o la terminal en VS Code
   2. En la carpeta del proyecto ejecuta:

        git add trabajos/
        git commit -m "Agregar archivos de trabajos"
        git push origin main

   3. Espera 1-2 minutos que GitHub Pages se actualice
   4. Los botones funcionarán automáticamente

   Los botones ya tienen las rutas correctas:
   → trabajos/unidad1/analisis-espacial-ENA/analisis.pdf
   → trabajos/unidad1/analisis-espacial-ENA/codigo.R

   Con Live Server local también funcionan si los archivos
   están en esas carpetas dentro de tu proyecto.

   ══════════════════════════════════════════════════════════ */

/* ════════════════════════════════════════════════════════════
   BASE DE DATOS DE TRABAJOS
   ════════════════════════════════════════════════════════════ */
const trabajos = [
  {
    id:          "ena-cultivos-229cde",
    nombre:      "Análisis Espacial de Cultivos Cosechados en Unidades Agropecuarias del Perú",
    unidad:      "u1",
    icono:       "🌾",

    /* Datos del estudio — se muestran en tarjeta */
    fuente:      "Censo Nacional Agropecuario",
    periodo:     "ENA 2014–2024",
    variable:    "Var229CDE",
    ambito:      "Nacional — Perú",

    /* Palabras clave como pills */
    pills: ["Moran's I", "LISA", "Autocorrelación", "R / spdep"],

    descripcion: "Estudio de dependencia espacial sobre la producción, venta y consumo propio de cultivos cosechados en unidades agropecuarias del Perú. Se aplican índices de autocorrelación global (Moran's I) y local (LISA) para identificar clústeres territoriales de actividad agrícola a nivel departamental y provincial.",

    /* Rutas relativas a la raíz del sitio (mismo para local y GitHub Pages) */
    pdf:    "trabajos/unidad1/analisis-espacial-ENA/analisis.pdf",
    codigo: "trabajos/unidad1/analisis-espacial-ENA/codigo.R",

    fecha: "2026"
  }

  ,{
    id:          "mastitis-vacas-sausalito",
    nombre:      "Pipeline de Mastitis Bovina — Establo Sausalito",
    unidad:      "u1",
    icono:       "🐄",

    fuente:      "Establo Sausalito",
    periodo:     "2022–2025",
    variable:    "VacaID · Tipo · DIM · Recidivas",
    ambito:      "Producción Lechera — Perú",

    pills: ["R Shiny", "Pipeline ETL", "Dashboard", "Datos Pecuarios"],

    descripcion: "Flujo automatizado de ingestión, limpieza, análisis y visualización de eventos de mastitis bovina a partir de registros históricos del Establo Sausalito (2022–2025). Incluye estandarización de fechas, clasificación de tipos (PI, AD, PD), cálculo de DIM, conteo de recidivas y un dashboard interactivo en R Shiny con 5 módulos: Resumen General, Análisis Mastitis, Tendencias, Perfil por Vaca y Tabla Completa — con filtros reactivos y exportación CSV.",

    pdf:    "trabajos/unidad1/VacasMastitis/analisis.pdf",
    codigo: "trabajos/unidad1/VacasMastitis/codigo.R",
    excel:  "trabajos/unidad1/VacasMastitis/datos.xlsx",
    appUrl: "https://denilzonrobtt.shinyapps.io/mastitisVACAS/",

    fecha: "Abril 2026"
  }

  ,{
    id:          "conceptos-vectorial-raster",
    nombre:      "Estadística Espacial: Capas Vectorial y Raster",
    unidad:      "u1",
    icono:       "🗺️",

    fuente:      "Trabajo Conceptual",
    periodo:     "2026",
    variable:    "Modelos Geoespaciales",
    ambito:      "Fundamentos Teóricos",

    pills: ["Vectorial", "Raster", "SIG", "Geoestadística"],

    descripcion: "Exposición de los conceptos fundamentales de la estadística espacial, centrada en los dos modelos principales de representación geoespacial: el modelo vectorial y el modelo raster. Se describen sus estructuras, propiedades estadísticas, principales operaciones y criterios de selección según el tipo de análisis requerido, con énfasis en el procesamiento de datos raster.",

    pdf:    "trabajos/unidad1/ConceptosEspacial/ConceptosEstadisticaEspacial.pdf",

    fecha: "2026"
  }

  ,{
    id:          "articulo-bayesiano-multietapa",
    nombre:      "Artículo: A Multi-Stage Bayesian Approach to Fit Spatial Point Process Models",
    unidad:      "u1",
    icono:       "📐",

    fuente:      "Artículo Científico",
    periodo:     "2026",
    variable:    "Proceso Puntual Espacial",
    ambito:      "Estadística Bayesiana Espacial",

    pills: ["Bayesiano", "Point Process", "Multi-Stage", "MCMC"],

    descripcion: "Exposición detallada del artículo científico 'A Multi-Stage Bayesian Approach to Fit Spatial Point Process Models', explicando sus métodos, procesos y autores mediante diapositivas. Se presenta el enfoque bayesiano multietapa para ajustar modelos de procesos puntuales espaciales, incluyendo el método de inferencia y las aplicaciones prácticas del modelo.",

    pdf:      "trabajos/unidad1/ArticuloBayesiano/Articulo Denilzon Multietapa.pdf",
    videoUrl: "https://www.loom.com/share/ed979cc791374cc8a96c8c7fae78fa3c",

    fecha: "2026"
  }

  ,{
    id:          "app-autocorrelacion-shiny",
    nombre:      "App Shiny: Análisis Interactivo de Autocorrelación Espacial",
    unidad:      "u1",
    icono:       "📡",

    fuente:      "Aplicación R Shiny",
    periodo:     "2026",
    variable:    "Moran's I · LISA",
    ambito:      "Múltiples Datasets",

    pills: ["Moran Global", "LISA", "Monte Carlo", "Leaflet"],

    descripcion: "Aplicación interactiva en R Shiny que calcula el Índice de Moran Global (I), identifica clústeres locales mediante LISA y permite analizar múltiples datasets espaciales (Carolina del Norte, Estados de EE.UU., Boston Housing y datos mundiales). La hipótesis nula plantea que los valores se distribuyen aleatoriamente en el espacio, evaluada mediante Z-score y complementada con simulación Monte Carlo de permutaciones aleatorias. Genera reportes automáticos en HTML, PDF y Word, y visualiza mapas interactivos con Leaflet.",

    pdf:    "trabajos/unidad1/AppAutocorrelacion/app_autocorrelacion.pdf",
    codigo: "trabajos/unidad1/AppAutocorrelacion/app.R",
    appUrl: "https://denilzonrobtt.shinyapps.io/autocorrelacion_app/",

    fecha: "2026"
  }

  ,{
    id:          "ivea-vulnerabilidad-alpacas",
    nombre:      "Compound Spatial Vulnerability Index for Alpaca Populations Facing Frost Risk in the Puno Altiplano, Peru (2019)",
    unidad:      "u1",
    icono:       "🦙",

    fuente:      "WorldClim v2.1 · SRTM · MIDAGRI 2019",
    periodo:     "2019",
    variable:    "IVEA — Índice Compuesto",
    ambito:      "109 distritos — Altiplano de Puno",

    pills: ["Kriging", "GWR", "Moran's I", "LISA", "Fisher-Jenks"],

    descripcion: "Artículo de investigación que presenta el Índice de Vulnerabilidad Espacial de Alpacas (IVEA), un índice compuesto que pondera temperatura mínima (35%), elevación (25%), densidad de alpacas (20%), precipitación anual (15%) y cobertura óptima del piso altitudinal (5%), aplicado a los 109 distritos del Altiplano de Puno —hogar de 2 035 280 alpacas, la mayor población del Perú—. Los valores se clasificaron con el algoritmo Fisher-Jenks; la estructura espacial se caracterizó con Moran's I y LISA; la temperatura mínima se interpoló mediante Kriging Ordinario con validación cruzada LOOCV; y la relación clima-densidad se modeló con Regresión Geográficamente Ponderada (GWR). Los resultados muestran que 48 distritos (43.6%) presentan vulnerabilidad Muy Alta, concentrados en las provincias de El Collao, Lampa, Melgar, San Antonio de Putina y Puno. Moran's I = 0.579 (p < 10⁻²²) confirmó un fuerte agrupamiento espacial positivo, mientras que el modelo GWR superó ampliamente a la regresión OLS global (R² = 0.646 vs. 0.164), revelando una marcada no estacionariedad espacial en la relación entre heladas y densidad de alpacas.",

    pdf: "trabajos/unidad1/PaperIVEA/PAPER_V1_FINAL.pdf",

    fecha: "2026"
  }

  /* ── Plantilla para el siguiente trabajo ──────────────────
  ,{
    id:          "id-unico-sin-espacios",
    nombre:      "Título completo del trabajo",
    unidad:      "u1",       // "u1" o "u2"
    icono:       "📊",
    fuente:      "Fuente de datos",
    periodo:     "Año",
    variable:    "Nombre de variable",
    ambito:      "Alcance geográfico",
    pills:       ["Método 1", "Método 2"],
    descripcion: "Descripción del análisis realizado.",
    pdf:         "trabajos/unidad1/nombre-carpeta/analisis.pdf",
    codigo:      "trabajos/unidad1/nombre-carpeta/codigo.R",  // opcional
    excel:       "trabajos/unidad1/nombre-carpeta/datos.xlsx", // opcional
    appUrl:      "",   // opcional — App Shiny u otra web
    videoUrl:    "",   // opcional — Loom, YouTube, etc.
    fecha:       "2026"
  }
  ──────────────────────────────────────────────────────────── */
];

/* ═══════════ ESTADO ════════════════════════════════════════ */
let filtroActivo = "all";

/* ═══════════ DOM ═══════════════════════════════════════════ */
const gridEl   = document.getElementById("trabajos-grid");
const buscarEl = document.getElementById("buscador");
const emptyEl  = document.getElementById("emptyState");
const totalEl  = document.getElementById("totalTrabajos");
const u1El     = document.getElementById("u1c");
const u2El     = document.getElementById("u2c");
const heroEl   = document.getElementById("counterWorks");

/* ═══════════ STATS ═════════════════════════════════════════ */
function actualizarStats() {
  const u1 = trabajos.filter(t => t.unidad === "u1").length;
  const u2 = trabajos.filter(t => t.unidad === "u2").length;
  if (totalEl) totalEl.textContent = trabajos.length;
  if (u1El)    u1El.textContent    = u1;
  if (u2El)    u2El.textContent    = u2;
  if (heroEl)  contarAnimar(heroEl, trabajos.length);
}

function contarAnimar(el, fin) {
  if (fin === 0) { el.textContent = 0; return; }
  let n = 0;
  const iv = setInterval(() => { n++; el.textContent = n; if (n >= fin) clearInterval(iv); }, 60);
}

/* ═══════════ CREAR BANNER SVG según unidad/tema ═══════════ */
function crearBannerSVG(t) {
  const isU2        = t.unidad === "u2";
  const isPecuario  = t.id && t.id.includes("mastitis");
  const isRaster    = t.id && t.id.includes("vectorial-raster");
  const isBayes     = t.id && t.id.includes("bayesiano");
  const isAutocorr  = t.id && t.id.includes("app-autocorrelacion");
  const isAlpaca    = t.id && t.id.includes("ivea-vulnerabilidad");

  /* ── Banner vectorial / raster ── */
  if (isRaster) {
    return `
    <svg viewBox="0 0 300 120" xmlns="http://www.w3.org/2000/svg"
         style="position:absolute;inset:0;width:100%;height:100%;opacity:0.75">
      <defs>
        <radialGradient id="grd-${t.id}" cx="30%" cy="50%" r="55%">
          <stop offset="0%" stop-color="#fbbf24" stop-opacity="0.12"/>
          <stop offset="100%" stop-color="#fbbf24" stop-opacity="0"/>
        </radialGradient>
        <radialGradient id="grd2-${t.id}" cx="72%" cy="50%" r="45%">
          <stop offset="0%" stop-color="#38bdf8" stop-opacity="0.1"/>
          <stop offset="100%" stop-color="#38bdf8" stop-opacity="0"/>
        </radialGradient>
      </defs>
      <rect width="300" height="120" fill="url(#grd-${t.id})"/>
      <rect width="300" height="120" fill="url(#grd2-${t.id})"/>

      <!-- LADO IZQUIERDO: Vectorial (polígonos + puntos + líneas) -->
      <text x="75" y="20" text-anchor="middle" font-size="7" fill="#fbbf24" opacity="0.7" font-family="monospace" font-weight="bold">VECTORIAL</text>
      <!-- Polígono -->
      <polygon points="30,35 70,28 90,55 65,75 25,68" fill="rgba(251,191,36,0.1)" stroke="#fbbf24" stroke-width="1.2" opacity="0.75"/>
      <!-- Línea -->
      <line x1="20" y1="90" x2="100" y2="85" stroke="#fbbf24" stroke-width="1.5" opacity="0.6"/>
      <!-- Puntos -->
      <circle cx="45" cy="50" r="3.5" fill="#fbbf24" opacity="0.85"/>
      <circle cx="75" cy="42" r="3"   fill="#fbbf24" opacity="0.75"/>
      <circle cx="60" cy="68" r="2.5" fill="#fbbf24" opacity="0.65"/>
      <circle cx="88" cy="90" r="2.5" fill="#fbbf24" opacity="0.6"/>

      <!-- Divisor central -->
      <line x1="150" y1="15" x2="150" y2="105" stroke="rgba(255,255,255,0.1)" stroke-width="1" stroke-dasharray="4,3"/>
      <text x="150" y="65" text-anchor="middle" font-size="9" fill="rgba(255,255,255,0.15)" font-family="monospace">vs</text>

      <!-- LADO DERECHO: Raster (cuadrícula de celdas con valores) -->
      <text x="225" y="20" text-anchor="middle" font-size="7" fill="#38bdf8" opacity="0.7" font-family="monospace" font-weight="bold">RASTER</text>
      <!-- Celdas de la grilla con distintas intensidades -->
      <rect x="162" y="27" width="20" height="20" rx="1" fill="rgba(56,189,248,0.08)"  stroke="rgba(56,189,248,0.3)" stroke-width="0.5"/>
      <rect x="182" y="27" width="20" height="20" rx="1" fill="rgba(56,189,248,0.18)"  stroke="rgba(56,189,248,0.3)" stroke-width="0.5"/>
      <rect x="202" y="27" width="20" height="20" rx="1" fill="rgba(56,189,248,0.32)"  stroke="rgba(56,189,248,0.3)" stroke-width="0.5"/>
      <rect x="222" y="27" width="20" height="20" rx="1" fill="rgba(56,189,248,0.55)"  stroke="rgba(56,189,248,0.3)" stroke-width="0.5"/>
      <rect x="242" y="27" width="20" height="20" rx="1" fill="rgba(56,189,248,0.72)"  stroke="rgba(56,189,248,0.3)" stroke-width="0.5"/>
      <rect x="162" y="47" width="20" height="20" rx="1" fill="rgba(56,189,248,0.22)"  stroke="rgba(56,189,248,0.3)" stroke-width="0.5"/>
      <rect x="182" y="47" width="20" height="20" rx="1" fill="rgba(56,189,248,0.45)"  stroke="rgba(56,189,248,0.3)" stroke-width="0.5"/>
      <rect x="202" y="47" width="20" height="20" rx="1" fill="rgba(56,189,248,0.65)"  stroke="rgba(56,189,248,0.3)" stroke-width="0.5"/>
      <rect x="222" y="47" width="20" height="20" rx="1" fill="rgba(56,189,248,0.80)"  stroke="rgba(56,189,248,0.3)" stroke-width="0.5"/>
      <rect x="242" y="47" width="20" height="20" rx="1" fill="rgba(56,189,248,0.90)"  stroke="rgba(56,189,248,0.3)" stroke-width="0.5"/>
      <rect x="162" y="67" width="20" height="20" rx="1" fill="rgba(56,189,248,0.12)"  stroke="rgba(56,189,248,0.3)" stroke-width="0.5"/>
      <rect x="182" y="67" width="20" height="20" rx="1" fill="rgba(56,189,248,0.28)"  stroke="rgba(56,189,248,0.3)" stroke-width="0.5"/>
      <rect x="202" y="67" width="20" height="20" rx="1" fill="rgba(56,189,248,0.50)"  stroke="rgba(56,189,248,0.3)" stroke-width="0.5"/>
      <rect x="222" y="67" width="20" height="20" rx="1" fill="rgba(56,189,248,0.35)"  stroke="rgba(56,189,248,0.3)" stroke-width="0.5"/>
      <rect x="242" y="67" width="20" height="20" rx="1" fill="rgba(56,189,248,0.60)"  stroke="rgba(56,189,248,0.3)" stroke-width="0.5"/>
      <rect x="162" y="87" width="20" height="18" rx="1" fill="rgba(56,189,248,0.06)"  stroke="rgba(56,189,248,0.3)" stroke-width="0.5"/>
      <rect x="182" y="87" width="20" height="18" rx="1" fill="rgba(56,189,248,0.15)"  stroke="rgba(56,189,248,0.3)" stroke-width="0.5"/>
      <rect x="202" y="87" width="20" height="18" rx="1" fill="rgba(56,189,248,0.38)"  stroke="rgba(56,189,248,0.3)" stroke-width="0.5"/>
      <rect x="222" y="87" width="20" height="18" rx="1" fill="rgba(56,189,248,0.22)"  stroke="rgba(56,189,248,0.3)" stroke-width="0.5"/>
      <rect x="242" y="87" width="20" height="18" rx="1" fill="rgba(56,189,248,0.48)"  stroke="rgba(56,189,248,0.3)" stroke-width="0.5"/>
    </svg>`;
  }

  /* ── Banner artículo bayesiano ── */
  if (isBayes) {
    return `
    <svg viewBox="0 0 300 120" xmlns="http://www.w3.org/2000/svg"
         style="position:absolute;inset:0;width:100%;height:100%;opacity:0.75">
      <defs>
        <radialGradient id="grd-${t.id}" cx="50%" cy="50%" r="55%">
          <stop offset="0%" stop-color="#a78bfa" stop-opacity="0.13"/>
          <stop offset="100%" stop-color="#a78bfa" stop-opacity="0"/>
        </radialGradient>
        <pattern id="grid-${t.id}" width="16" height="16" patternUnits="userSpaceOnUse">
          <path d="M16 0H0V16" fill="none" stroke="#a78bfa" stroke-width="0.3" opacity="0.18"/>
        </pattern>
      </defs>
      <rect width="300" height="120" fill="url(#grd-${t.id})"/>
      <rect width="300" height="120" fill="url(#grid-${t.id})"/>

      <!-- Curva distribución posterior (campana bayesiana) -->
      <path d="M 20,95 Q 50,95 70,70 Q 90,45 110,28 Q 130,12 150,10 Q 170,12 190,28 Q 210,45 230,70 Q 250,95 280,95"
            fill="rgba(167,139,250,0.12)" stroke="#a78bfa" stroke-width="1.5" opacity="0.8"/>
      <!-- Prior más ancha -->
      <path d="M 20,95 Q 60,95 90,65 Q 120,35 150,28 Q 180,35 210,65 Q 240,95 280,95"
            fill="none" stroke="rgba(167,139,250,0.35)" stroke-width="1" opacity="0.6" stroke-dasharray="5,3"/>
      <!-- Likelihood -->
      <path d="M 80,95 Q 105,95 120,55 Q 135,22 150,15 Q 165,22 180,55 Q 195,95 220,95"
            fill="none" stroke="rgba(244,114,182,0.45)" stroke-width="1" opacity="0.7" stroke-dasharray="3,2"/>

      <!-- Eje X -->
      <line x1="15" y1="95" x2="285" y2="95" stroke="rgba(255,255,255,0.15)" stroke-width="1"/>
      <!-- Línea de moda posterior -->
      <line x1="150" y1="10" x2="150" y2="95" stroke="rgba(167,139,250,0.4)" stroke-width="1" stroke-dasharray="3,2"/>

      <!-- Etiquetas -->
      <text x="40"  y="108" text-anchor="middle" font-size="6" fill="rgba(167,139,250,0.6)" font-family="monospace">Prior</text>
      <text x="150" y="108" text-anchor="middle" font-size="6" fill="rgba(167,139,250,0.9)" font-family="monospace" font-weight="bold">Posterior</text>
      <text x="260" y="108" text-anchor="middle" font-size="6" fill="rgba(244,114,182,0.6)" font-family="monospace">Likelihood</text>

      <!-- Puntos de proceso puntual espacial (arriba izquierda) -->
      <circle cx="22"  cy="22" r="2.5" fill="#a78bfa" opacity="0.6"/>
      <circle cx="35"  cy="30" r="2"   fill="#a78bfa" opacity="0.5"/>
      <circle cx="28"  cy="40" r="2.5" fill="#f472b6" opacity="0.55"/>
      <circle cx="44"  cy="18" r="2"   fill="#a78bfa" opacity="0.45"/>
      <circle cx="52"  cy="35" r="2"   fill="#a78bfa" opacity="0.5"/>
      <circle cx="38"  cy="50" r="1.5" fill="#f472b6" opacity="0.45"/>

      <!-- Badge ecuación -->
      <rect x="220" y="14" width="68" height="22" rx="4"
            fill="rgba(167,139,250,0.1)" stroke="rgba(167,139,250,0.3)" stroke-width="0.8"/>
      <text x="254" y="22" text-anchor="middle" font-size="5.5" fill="#a78bfa" opacity="0.85" font-family="monospace">π(θ|y) ∝</text>
      <text x="254" y="31" text-anchor="middle" font-size="5.5" fill="#a78bfa" opacity="0.85" font-family="monospace">L(y|θ)·π(θ)</text>
    </svg>`;
  }

  /* ── Banner App Autocorrelación (mapa choropleth + Z-score) ── */
  if (isAutocorr) {
    return `
    <svg viewBox="0 0 300 120" xmlns="http://www.w3.org/2000/svg"
         style="position:absolute;inset:0;width:100%;height:100%;opacity:0.78">
      <defs>
        <radialGradient id="grd-${t.id}" cx="50%" cy="50%" r="55%">
          <stop offset="0%" stop-color="#38bdf8" stop-opacity="0.12"/>
          <stop offset="100%" stop-color="#38bdf8" stop-opacity="0"/>
        </radialGradient>
      </defs>
      <rect width="300" height="120" fill="url(#grd-${t.id})"/>

      <!-- Mapa choropleth hexagonal (polígonos vecinos coloreados) -->
      <polygon points="40,30 60,22 80,30 80,50 60,58 40,50" fill="rgba(215,25,28,0.55)" stroke="rgba(255,255,255,0.15)" stroke-width="0.6"/>
      <polygon points="80,30 100,22 120,30 120,50 100,58 80,50" fill="rgba(215,25,28,0.4)" stroke="rgba(255,255,255,0.15)" stroke-width="0.6"/>
      <polygon points="60,58 80,50 100,58 100,78 80,86 60,78" fill="rgba(215,25,28,0.35)" stroke="rgba(255,255,255,0.15)" stroke-width="0.6"/>
      <polygon points="100,58 120,50 140,58 140,78 120,86 100,78" fill="rgba(44,123,182,0.3)" stroke="rgba(255,255,255,0.15)" stroke-width="0.6"/>
      <polygon points="120,30 140,22 160,30 160,50 140,58 120,50" fill="rgba(204,204,204,0.25)" stroke="rgba(255,255,255,0.15)" stroke-width="0.6"/>
      <polygon points="140,58 160,50 180,58 180,78 160,86 140,78" fill="rgba(44,123,182,0.45)" stroke="rgba(255,255,255,0.15)" stroke-width="0.6"/>
      <polygon points="160,30 180,22 200,30 200,50 180,58 160,50" fill="rgba(44,123,182,0.55)" stroke="rgba(255,255,255,0.15)" stroke-width="0.6"/>
      <polygon points="180,58 200,50 220,58 220,78 200,86 180,78" fill="rgba(44,123,182,0.6)" stroke="rgba(255,255,255,0.15)" stroke-width="0.6"/>

      <!-- Panel Z-score / fórmula -->
      <rect x="232" y="22" width="56" height="56" rx="6" fill="rgba(56,189,248,0.1)" stroke="rgba(56,189,248,0.32)" stroke-width="0.8"/>
      <text x="260" y="38" text-anchor="middle" font-size="6.5" fill="#38bdf8" opacity="0.9" font-family="monospace" font-weight="bold">Moran's I</text>
      <text x="260" y="52" text-anchor="middle" font-size="6" fill="#38bdf8" opacity="0.8" font-family="monospace">Z = (I−E[I])</text>
      <text x="260" y="61" text-anchor="middle" font-size="6" fill="#38bdf8" opacity="0.8" font-family="monospace">  /√Var[I]</text>
      <text x="260" y="73" text-anchor="middle" font-size="5" fill="#34d399" opacity="0.85" font-family="monospace">p-MC &lt; 0.05</text>

      <!-- Etiqueta Leaflet -->
      <text x="20" y="100" font-size="5.5" fill="rgba(255,255,255,0.4)" font-family="monospace">📍 Leaflet · HTML/PDF/Word</text>
    </svg>`;
  }

  /* ── Banner IVEA Alpacas (heladas + altiplano) ── */
  if (isAlpaca) {
    return `
    <svg viewBox="0 0 300 120" xmlns="http://www.w3.org/2000/svg"
         style="position:absolute;inset:0;width:100%;height:100%;opacity:0.78">
      <defs>
        <linearGradient id="sky-${t.id}" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%"  stop-color="#38bdf8" stop-opacity="0.16"/>
          <stop offset="100%" stop-color="#38bdf8" stop-opacity="0.02"/>
        </linearGradient>
      </defs>
      <rect width="300" height="120" fill="url(#sky-${t.id})"/>

      <!-- Silueta de montañas del altiplano -->
      <polygon points="0,90 35,55 60,75 90,40 120,68 150,48 180,72 210,50 240,78 270,58 300,85 300,120 0,120"
               fill="rgba(167,139,250,0.10)" stroke="rgba(167,139,250,0.3)" stroke-width="1"/>
      <polygon points="0,100 40,72 75,88 110,62 145,84 180,66 215,90 250,70 300,95 300,120 0,120"
               fill="rgba(56,189,248,0.12)" stroke="rgba(56,189,248,0.28)" stroke-width="1"/>

      <!-- Copos de nieve / helada (puntos dispersos arriba) -->
      <circle cx="40"  cy="18" r="1.5" fill="#a8c0d6" opacity="0.7"/>
      <circle cx="70"  cy="12" r="1.2" fill="#a8c0d6" opacity="0.6"/>
      <circle cx="110" cy="22" r="1.6" fill="#a8c0d6" opacity="0.65"/>
      <circle cx="150" cy="10" r="1.3" fill="#a8c0d6" opacity="0.55"/>
      <circle cx="190" cy="20" r="1.5" fill="#a8c0d6" opacity="0.6"/>
      <circle cx="230" cy="14" r="1.2" fill="#a8c0d6" opacity="0.5"/>
      <circle cx="265" cy="24" r="1.4" fill="#a8c0d6" opacity="0.6"/>

      <!-- Distritos como puntos de severidad (heatmap simulando los 109 distritos) -->
      <circle cx="55"  cy="92" r="4.5" fill="#dc2626" opacity="0.75"/>
      <circle cx="78"  cy="80" r="3.5" fill="#dc2626" opacity="0.65"/>
      <circle cx="100" cy="95" r="4"   fill="#f97316" opacity="0.65"/>
      <circle cx="130" cy="78" r="3"   fill="#fbbf24" opacity="0.6"/>
      <circle cx="155" cy="92" r="4.5" fill="#dc2626" opacity="0.7"/>
      <circle cx="180" cy="82" r="3"   fill="#f97316" opacity="0.55"/>
      <circle cx="205" cy="96" r="3.8" fill="#fbbf24" opacity="0.6"/>
      <circle cx="230" cy="85" r="3.2" fill="#34d399" opacity="0.5"/>
      <circle cx="252" cy="98" r="3"   fill="#34d399" opacity="0.5"/>

      <!-- Badge IVEA -->
      <rect x="14" y="14" width="64" height="24" rx="5" fill="rgba(167,139,250,0.14)" stroke="rgba(167,139,250,0.35)" stroke-width="0.8"/>
      <text x="46" y="24" text-anchor="middle" font-size="6.5" fill="#a78bfa" opacity="0.95" font-family="monospace" font-weight="bold">IVEA</text>
      <text x="46" y="33" text-anchor="middle" font-size="4.8" fill="#a78bfa" opacity="0.75" font-family="monospace">109 distritos</text>

      <!-- Badge Moran's I -->
      <rect x="220" y="14" width="68" height="24" rx="5" fill="rgba(220,38,38,0.12)" stroke="rgba(220,38,38,0.32)" stroke-width="0.8"/>
      <text x="254" y="24" text-anchor="middle" font-size="6" fill="#f87171" opacity="0.95" font-family="monospace">I = 0.579</text>
      <text x="254" y="33" text-anchor="middle" font-size="4.5" fill="#f87171" opacity="0.7" font-family="monospace">p &lt; 10⁻²²</text>
    </svg>`;
  }

  /* ── Banner ganadero / pipeline ── */
  if (isPecuario) {
    return `
    <svg viewBox="0 0 300 120" xmlns="http://www.w3.org/2000/svg"
         style="position:absolute;inset:0;width:100%;height:100%;opacity:0.75">
      <defs>
        <pattern id="grid-${t.id}" width="18" height="18" patternUnits="userSpaceOnUse">
          <path d="M18 0H0V18" fill="none" stroke="#34d399" stroke-width="0.3" opacity="0.2"/>
        </pattern>
        <radialGradient id="grd-${t.id}" cx="50%" cy="50%" r="55%">
          <stop offset="0%" stop-color="#34d399" stop-opacity="0.12"/>
          <stop offset="100%" stop-color="#34d399" stop-opacity="0"/>
        </radialGradient>
      </defs>
      <rect width="300" height="120" fill="url(#grd-${t.id})"/>
      <rect width="300" height="120" fill="url(#grid-${t.id})"/>
      <rect x="18" y="46" width="38" height="28" rx="5" fill="rgba(52,211,153,0.12)" stroke="#34d399" stroke-width="1" opacity="0.7"/>
      <text x="37" y="57" text-anchor="middle" font-size="6" fill="#34d399" opacity="0.9" font-family="monospace">CSV</text>
      <text x="37" y="67" text-anchor="middle" font-size="5" fill="#34d399" opacity="0.6" font-family="monospace">Extracción</text>
      <line x1="56" y1="60" x2="72" y2="60" stroke="#34d399" stroke-width="1" opacity="0.5" stroke-dasharray="3,2"/>
      <polygon points="72,57 78,60 72,63" fill="#34d399" opacity="0.5"/>
      <rect x="78" y="46" width="38" height="28" rx="5" fill="rgba(52,211,153,0.12)" stroke="#34d399" stroke-width="1" opacity="0.7"/>
      <text x="97" y="57" text-anchor="middle" font-size="6" fill="#34d399" opacity="0.9" font-family="monospace">ETL</text>
      <text x="97" y="67" text-anchor="middle" font-size="5" fill="#34d399" opacity="0.6" font-family="monospace">Limpieza</text>
      <line x1="116" y1="60" x2="132" y2="60" stroke="#34d399" stroke-width="1" opacity="0.5" stroke-dasharray="3,2"/>
      <polygon points="132,57 138,60 132,63" fill="#34d399" opacity="0.5"/>
      <rect x="138" y="46" width="38" height="28" rx="5" fill="rgba(56,189,248,0.12)" stroke="#38bdf8" stroke-width="1" opacity="0.7"/>
      <text x="157" y="57" text-anchor="middle" font-size="6" fill="#38bdf8" opacity="0.9" font-family="monospace">Stats</text>
      <text x="157" y="67" text-anchor="middle" font-size="5" fill="#38bdf8" opacity="0.6" font-family="monospace">Análisis</text>
      <line x1="176" y1="60" x2="192" y2="60" stroke="#38bdf8" stroke-width="1" opacity="0.5" stroke-dasharray="3,2"/>
      <polygon points="192,57 198,60 192,63" fill="#38bdf8" opacity="0.5"/>
      <rect x="198" y="40" width="48" height="40" rx="6" fill="rgba(167,139,250,0.15)" stroke="#a78bfa" stroke-width="1.5" opacity="0.9"/>
      <text x="222" y="56" text-anchor="middle" font-size="6.5" fill="#a78bfa" opacity="1" font-family="monospace" font-weight="bold">Shiny</text>
      <text x="222" y="67" text-anchor="middle" font-size="5" fill="#a78bfa" opacity="0.75" font-family="monospace">Dashboard</text>
      <text x="222" y="76" text-anchor="middle" font-size="4.5" fill="#a78bfa" opacity="0.6" font-family="monospace">5 módulos</text>
      <rect x="260" y="30" width="6" height="60" rx="3" fill="rgba(255,255,255,0.05)" stroke="rgba(255,255,255,0.08)" stroke-width="0.5"/>
      <rect x="260" y="68" width="6" height="22" rx="3" fill="#f472b6" opacity="0.55"/>
      <rect x="269" y="30" width="6" height="60" rx="3" fill="rgba(255,255,255,0.05)" stroke="rgba(255,255,255,0.08)" stroke-width="0.5"/>
      <rect x="269" y="50" width="6" height="40" rx="3" fill="#34d399" opacity="0.55"/>
      <rect x="278" y="30" width="6" height="60" rx="3" fill="rgba(255,255,255,0.05)" stroke="rgba(255,255,255,0.08)" stroke-width="0.5"/>
      <rect x="278" y="42" width="6" height="48" rx="3" fill="#38bdf8" opacity="0.55"/>
      <text x="37"  y="38" text-anchor="middle" font-size="4.5" fill="rgba(255,255,255,0.3)" font-family="monospace">01</text>
      <text x="97"  y="38" text-anchor="middle" font-size="4.5" fill="rgba(255,255,255,0.3)" font-family="monospace">02</text>
      <text x="157" y="38" text-anchor="middle" font-size="4.5" fill="rgba(255,255,255,0.3)" font-family="monospace">03</text>
      <text x="222" y="32" text-anchor="middle" font-size="4.5" fill="rgba(255,255,255,0.3)" font-family="monospace">04</text>
    </svg>`;
  }

  /* ── Banner espacial (default) ── */
  const c1 = isU2 ? "#a78bfa" : "#38bdf8";
  const c2 = isU2 ? "#f472b6" : "#34d399";

  return `
    <svg viewBox="0 0 300 120" xmlns="http://www.w3.org/2000/svg"
         style="position:absolute;inset:0;width:100%;height:100%;opacity:0.7">
      <defs>
        <pattern id="grid-${t.id}" width="20" height="20" patternUnits="userSpaceOnUse">
          <path d="M20 0H0V20" fill="none" stroke="${c1}" stroke-width="0.4" opacity="0.25"/>
        </pattern>
        <radialGradient id="grd-${t.id}" cx="50%" cy="50%" r="50%">
          <stop offset="0%" stop-color="${c1}" stop-opacity="0.15"/>
          <stop offset="100%" stop-color="${c1}" stop-opacity="0"/>
        </radialGradient>
      </defs>
      <rect width="300" height="120" fill="url(#grd-${t.id})"/>
      <rect width="300" height="120" fill="url(#grid-${t.id})"/>
      <circle cx="60"  cy="45"  r="5"   fill="${c1}" opacity="0.85"/>
      <circle cx="110" cy="30"  r="4"   fill="${c1}" opacity="0.75"/>
      <circle cx="90"  cy="75"  r="6"   fill="${c2}" opacity="0.7"/>
      <circle cx="160" cy="55"  r="5"   fill="${c1}" opacity="0.8"/>
      <circle cx="195" cy="35"  r="3.5" fill="${c2}" opacity="0.65"/>
      <circle cx="145" cy="85"  r="4"   fill="${c1}" opacity="0.6"/>
      <circle cx="230" cy="65"  r="5.5" fill="${c2}" opacity="0.8"/>
      <circle cx="255" cy="40"  r="3"   fill="${c1}" opacity="0.55"/>
      <circle cx="215" cy="90"  r="4.5" fill="${c1}" opacity="0.7"/>
      <circle cx="40"  cy="85"  r="3.5" fill="${c2}" opacity="0.6"/>
      <circle cx="270" cy="80"  r="3"   fill="${c2}" opacity="0.55"/>
      <line x1="60"  y1="45"  x2="110" y2="30"  stroke="${c1}" stroke-width="0.7" opacity="0.3" stroke-dasharray="3,2"/>
      <line x1="60"  y1="45"  x2="90"  y2="75"  stroke="${c1}" stroke-width="0.7" opacity="0.3" stroke-dasharray="3,2"/>
      <line x1="110" y1="30"  x2="160" y2="55"  stroke="${c1}" stroke-width="0.7" opacity="0.3" stroke-dasharray="3,2"/>
      <line x1="90"  y1="75"  x2="145" y2="85"  stroke="${c2}" stroke-width="0.7" opacity="0.3" stroke-dasharray="3,2"/>
      <line x1="160" y1="55"  x2="195" y2="35"  stroke="${c1}" stroke-width="0.7" opacity="0.28" stroke-dasharray="3,2"/>
      <line x1="160" y1="55"  x2="145" y2="85"  stroke="${c1}" stroke-width="0.7" opacity="0.28" stroke-dasharray="3,2"/>
      <line x1="195" y1="35"  x2="230" y2="65"  stroke="${c2}" stroke-width="0.7" opacity="0.28" stroke-dasharray="3,2"/>
      <line x1="230" y1="65"  x2="215" y2="90"  stroke="${c1}" stroke-width="0.7" opacity="0.28" stroke-dasharray="3,2"/>
      <circle cx="160" cy="55" r="28" fill="none" stroke="${c1}" stroke-width="1" opacity="0.12" stroke-dasharray="4,3"/>
      <circle cx="160" cy="55" r="40" fill="none" stroke="${c1}" stroke-width="0.6" opacity="0.07" stroke-dasharray="6,4"/>
    </svg>`;
}

/* ═══════════ CREAR PILLS DE KEYWORDS ══════════════════════ */
const pillColors = ["tc-pill-sky", "tc-pill-green", "tc-pill-amber", "tc-pill-sky"];

function crearPills(pills = []) {
  return pills.map((p, i) =>
    `<span class="tc-pill ${pillColors[i % pillColors.length]}">${p}</span>`
  ).join("");
}

/* ═══════════ CREAR TARJETA ═════════════════════════════════ */
function crearTarjeta(t, delay) {
  const esU2   = t.unidad === "u2";
  const tagCls = esU2 ? "u2" : "";
  const tagTxt = esU2 ? "Unidad 2" : "Unidad 1";
  const num    = String(t.id).slice(-3).replace(/\D/g, "").padStart(2, "0") || "01";

  return `
<div class="trab-card reveal" style="animation-delay:${delay}ms">

  <!-- Banner visual -->
  <div class="tc-banner">
    <div class="tc-banner-vis">${crearBannerSVG(t)}</div>
    <div class="tc-banner-tag">
      <span class="tc-unidad-tag ${tagCls}">${tagTxt}</span>
    </div>
    <div class="tc-banner-num">#${num}</div>
    <div class="tc-banner-icon">${t.icono}</div>
  </div>

  <!-- Cuerpo -->
  <div class="tc-body">

    <h3 class="tc-title">${t.nombre}</h3>

    <!-- Pills de metodología -->
    <div class="tc-intro-line">
      ${crearPills(t.pills)}
    </div>

    <p class="tc-desc">${t.descripcion}</p>

    <!-- Datos del estudio -->
    <div class="tc-data-grid">
      <div class="tc-data-item">
        <span class="tc-data-label">Fuente</span>
        <span class="tc-data-val">${t.fuente || "—"}</span>
      </div>
      <div class="tc-data-item">
        <span class="tc-data-label">Período</span>
        <span class="tc-data-val">${t.periodo || "—"}</span>
      </div>
      <div class="tc-data-item">
        <span class="tc-data-label">Variable</span>
        <span class="tc-data-val">${t.variable || "—"}</span>
      </div>
      <div class="tc-data-item">
        <span class="tc-data-label">Ámbito</span>
        <span class="tc-data-val">${t.ambito || "—"}</span>
      </div>
    </div>

    <div class="tc-divider"></div>

    <!-- Acciones -->
    <div class="tc-acciones">

      <div>
        <div class="ac-label">Informe PDF</div>
        <div class="ac-row">
          <a href="${t.pdf}" target="_blank" rel="noopener noreferrer" class="btn-ac">
            📄 Ver PDF
          </a>
          <a href="${t.pdf}" download class="btn-ac btn-ac-dl">
            ⬇ Descargar PDF
          </a>
        </div>
      </div>

      ${t.codigo ? `
      <div>
        <div class="ac-label">Código Fuente (.R)</div>
        <div class="ac-row">
          <a href="${t.codigo}" target="_blank" rel="noopener noreferrer" class="btn-ac">
            💻 Ver Código
          </a>
          <a href="${t.codigo}" download class="btn-ac btn-ac-dl">
            ⬇ Descargar .R
          </a>
        </div>
      </div>` : ""}

      ${t.excel ? `
      <div>
        <div class="ac-label">Datos Excel</div>
        <div class="ac-row">
          <a href="${t.excel}" download class="btn-ac btn-ac-dl">
            📊 Descargar Excel
          </a>
        </div>
      </div>` : ""}

      ${t.videoUrl ? `
      <div>
        <div class="ac-label">Exposición en Video</div>
        <div class="ac-row">
          <a href="${t.videoUrl}" target="_blank" rel="noopener noreferrer" class="btn-ac btn-ac-video">
            🎬 Ver Video (Loom)
          </a>
        </div>
      </div>` : ""}

      ${t.appUrl ? `
      <div>
        <div class="ac-label">Aplicación Web</div>
        <div class="ac-row">
          <a href="${t.appUrl}" target="_blank" rel="noopener noreferrer" class="btn-ac btn-ac-app">
            🚀 Abrir App Shiny
          </a>
        </div>
      </div>` : ""}

      ${t.fecha ? `<p class="tc-fecha">Entregado: ${t.fecha}</p>` : ""}
    </div>

  </div>
</div>`;
}

/* ═══════════ MOSTRAR ═══════════════════════════════════════ */
function mostrar(data) {
  if (!gridEl) return;
  if (data.length === 0) {
    gridEl.innerHTML = "";
    emptyEl?.classList.remove("hidden");
    return;
  }
  emptyEl?.classList.add("hidden");
  gridEl.innerHTML = data.map((t, i) => crearTarjeta(t, i * 90)).join("");

  setTimeout(() => {
    gridEl.querySelectorAll(".reveal").forEach(el => el.classList.add("visible"));
  }, 60);
}

/* ═══════════ FILTRAR ═══════════════════════════════════════ */
function filtrar(tipo) {
  filtroActivo = tipo;
  document.querySelectorAll(".fbtn").forEach(b =>
    b.classList.toggle("active", b.dataset.f === tipo)
  );
  aplicar(tipo, buscarEl?.value.toLowerCase() || "");
}
window.filtrar = filtrar;

function aplicar(tipo, texto) {
  let res = tipo === "all" ? trabajos : trabajos.filter(t => t.unidad === tipo);
  if (texto.trim()) {
    res = res.filter(t =>
      t.nombre.toLowerCase().includes(texto) ||
      t.descripcion.toLowerCase().includes(texto) ||
      (t.variable || "").toLowerCase().includes(texto)
    );
  }
  mostrar(res);
}

buscarEl?.addEventListener("input", e =>
  aplicar(filtroActivo, e.target.value.toLowerCase())
);

/* ═══════════ NAVBAR SCROLL ═════════════════════════════════ */
const navbarEl = document.getElementById("navbar");
window.addEventListener("scroll", () =>
  navbarEl?.classList.toggle("scrolled", window.scrollY > 55)
);

/* ═══════════ NAVLINK ACTIVO ════════════════════════════════ */
const allSections = document.querySelectorAll("section[id]");
const allNavLinks = document.querySelectorAll(".nav-link");
const secObs = new IntersectionObserver(entries => {
  entries.forEach(e => {
    if (e.isIntersecting) {
      allNavLinks.forEach(l =>
        l.classList.toggle("active", l.getAttribute("href") === `#${e.target.id}`)
      );
    }
  });
}, { threshold: 0.35 });
allSections.forEach(s => secObs.observe(s));

/* ═══════════ REVEAL SCROLL ═════════════════════════════════ */
const revObs = new IntersectionObserver(entries => {
  entries.forEach(e => { if (e.isIntersecting) e.target.classList.add("visible"); });
}, { threshold: 0.08 });
document.querySelectorAll(".reveal").forEach(el => revObs.observe(el));

/* ═══════════ MOBILE NAV ════════════════════════════════════ */
const mnav = document.createElement("div");
mnav.className = "mnav";
mnav.innerHTML = `
  <button class="mnav-close" id="mnavClose">✕</button>
  <a href="#inicio"   onclick="this.closest('.mnav').classList.remove('open')">Inicio</a>
  <a href="#perfil"   onclick="this.closest('.mnav').classList.remove('open')">Perfil</a>
  <a href="#temas"    onclick="this.closest('.mnav').classList.remove('open')">Temas</a>
  <a href="#trabajos" onclick="this.closest('.mnav').classList.remove('open')">Trabajos</a>
`;
document.body.appendChild(mnav);
document.getElementById("navToggle")?.addEventListener("click", () => mnav.classList.add("open"));
document.getElementById("mnavClose")?.addEventListener("click", () => mnav.classList.remove("open"));

/* ═══════════ PAGE LOADER ═══════════════════════════════════ */
window.addEventListener("load", () => {
  setTimeout(() => {
    document.getElementById("pageLoader")?.classList.add("done");
  }, 1400);

  /* Reveal cards estáticas */
  document.querySelectorAll(".pcard, .tcard, .dstat").forEach(el => {
    el.classList.add("reveal");
    revObs.observe(el);
  });
});

/* ═══════════ INICIAR ═══════════════════════════════════════ */
actualizarStats();
mostrar(trabajos);