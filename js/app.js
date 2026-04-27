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

    pdf:    "trabajos/unidad1/VacasMastitis/pipelineVacas.pdf",
    codigo: "trabajos/unidad1/VacasMastitis/app.R",
    excel:  "trabajos/unidad1/VacasMastitis/vacas_mastitis.xlsx",
    appUrl: "https://denilzonrobtt.shinyapps.io/mastitisVACAS/",

    fecha: "Abril 2026"
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
    codigo:      "trabajos/unidad1/nombre-carpeta/codigo.R",
    excel:       "trabajos/unidad1/nombre-carpeta/datos.xlsx",  // opcional
    appUrl:      "",                                            // opcional
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
  const isU2      = t.unidad === "u2";
  const isPecuario = t.id && t.id.includes("mastitis");

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

      <!-- Etapas del pipeline ETL como nodos conectados -->
      <!-- Nodo 1: CSV -->
      <rect x="18" y="46" width="38" height="28" rx="5"
            fill="rgba(52,211,153,0.12)" stroke="#34d399" stroke-width="1" opacity="0.7"/>
      <text x="37" y="57" text-anchor="middle" font-size="6" fill="#34d399" opacity="0.9" font-family="monospace">CSV</text>
      <text x="37" y="67" text-anchor="middle" font-size="5" fill="#34d399" opacity="0.6" font-family="monospace">Extracción</text>

      <!-- Flecha 1→2 -->
      <line x1="56" y1="60" x2="72" y2="60" stroke="#34d399" stroke-width="1" opacity="0.5" stroke-dasharray="3,2"/>
      <polygon points="72,57 78,60 72,63" fill="#34d399" opacity="0.5"/>

      <!-- Nodo 2: Clean -->
      <rect x="78" y="46" width="38" height="28" rx="5"
            fill="rgba(52,211,153,0.12)" stroke="#34d399" stroke-width="1" opacity="0.7"/>
      <text x="97" y="57" text-anchor="middle" font-size="6" fill="#34d399" opacity="0.9" font-family="monospace">ETL</text>
      <text x="97" y="67" text-anchor="middle" font-size="5" fill="#34d399" opacity="0.6" font-family="monospace">Limpieza</text>

      <!-- Flecha 2→3 -->
      <line x1="116" y1="60" x2="132" y2="60" stroke="#34d399" stroke-width="1" opacity="0.5" stroke-dasharray="3,2"/>
      <polygon points="132,57 138,60 132,63" fill="#34d399" opacity="0.5"/>

      <!-- Nodo 3: Análisis -->
      <rect x="138" y="46" width="38" height="28" rx="5"
            fill="rgba(56,189,248,0.12)" stroke="#38bdf8" stroke-width="1" opacity="0.7"/>
      <text x="157" y="57" text-anchor="middle" font-size="6" fill="#38bdf8" opacity="0.9" font-family="monospace">Stats</text>
      <text x="157" y="67" text-anchor="middle" font-size="5" fill="#38bdf8" opacity="0.6" font-family="monospace">Análisis</text>

      <!-- Flecha 3→4 -->
      <line x1="176" y1="60" x2="192" y2="60" stroke="#38bdf8" stroke-width="1" opacity="0.5" stroke-dasharray="3,2"/>
      <polygon points="192,57 198,60 192,63" fill="#38bdf8" opacity="0.5"/>

      <!-- Nodo 4: Shiny (destacado) -->
      <rect x="198" y="40" width="48" height="40" rx="6"
            fill="rgba(167,139,250,0.15)" stroke="#a78bfa" stroke-width="1.5" opacity="0.9"/>
      <text x="222" y="56" text-anchor="middle" font-size="6.5" fill="#a78bfa" opacity="1" font-family="monospace" font-weight="bold">Shiny</text>
      <text x="222" y="67" text-anchor="middle" font-size="5" fill="#a78bfa" opacity="0.75" font-family="monospace">Dashboard</text>
      <text x="222" y="76" text-anchor="middle" font-size="4.5" fill="#a78bfa" opacity="0.6" font-family="monospace">5 módulos</text>

      <!-- Indicadores de recidivas (barra lateral) -->
      <rect x="260" y="30" width="6" height="60" rx="3" fill="rgba(255,255,255,0.05)" stroke="rgba(255,255,255,0.08)" stroke-width="0.5"/>
      <rect x="260" y="68" width="6" height="22" rx="3" fill="#f472b6" opacity="0.55"/>
      <rect x="269" y="30" width="6" height="60" rx="3" fill="rgba(255,255,255,0.05)" stroke="rgba(255,255,255,0.08)" stroke-width="0.5"/>
      <rect x="269" y="50" width="6" height="40" rx="3" fill="#34d399" opacity="0.55"/>
      <rect x="278" y="30" width="6" height="60" rx="3" fill="rgba(255,255,255,0.05)" stroke="rgba(255,255,255,0.08)" stroke-width="0.5"/>
      <rect x="278" y="42" width="6" height="48" rx="3" fill="#38bdf8" opacity="0.55"/>

      <!-- Labels top -->
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
      </div>

      ${t.excel ? `
      <div>
        <div class="ac-label">Datos Excel</div>
        <div class="ac-row">
          <a href="${t.excel}" download class="btn-ac btn-ac-dl">
            📊 Descargar Excel
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