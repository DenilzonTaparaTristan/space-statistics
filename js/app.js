/* ============================================================
   app.js — Space Statistics · Lógica principal
   ============================================================

   ┌─ ESTRUCTURA DE ARCHIVOS REQUERIDA ──────────────────────┐
   │  trabajos/                                              │
   │    unidad1/                                             │
   │      analisis-espacial-ENA/    ← nombre EXACTO         │
   │        analisis.pdf                                     │
   │        codigo.R                                         │
   │    unidad2/                                             │
   │      (futuros trabajos)                                 │
   └──────────────────────────────────────────────────────────┘

   ┌─ POR QUÉ FALLAN LOS BOTONES ────────────────────────────┐
   │  Causa más común: el nombre de carpeta no coincide.     │
   │  En el repo GitHub está "analisis-espacial-ENA" pero    │
   │  el código decía "analisis-espacial/".                  │
   │                                                         │
   │  Live Server con CORS: el atributo `download` solo      │
   │  funciona con archivos del MISMO origen. En Live Server  │
   │  esto va bien. En GitHub Pages también, porque los       │
   │  archivos están en el mismo dominio.                    │
   │                                                         │
   │  Si el PDF aún no abre: verifica que el archivo esté    │
   │  commiteado en GitHub (no solo en tu PC local).         │
   └──────────────────────────────────────────────────────────┘
*/

/* ════════════════════════════════════════════════════════════
   BASE DE DATOS DE TRABAJOS
   Para agregar uno nuevo: copia el bloque comentado abajo,
   pégalo dentro del array y edita los campos.
   ════════════════════════════════════════════════════════════ */
const trabajos = [
  {
    id:          "ena-cultivos",
    nombre:      "Análisis Espacial de Cultivos Cosechados",
    unidad:      "u1",
    icono:       "🌾",
    descripcion: "Estudio basado en el Censo Nacional Agropecuario (ENA 2014-2024), analizando producción, venta y consumo de cultivos cosechados en unidades agropecuarias del Perú mediante técnicas de estadística espacial.",
    pdf:    "trabajos/unidad1/analisis-espacial-ENA/analisis.pdf",
    codigo: "trabajos/unidad1/analisis-espacial-ENA/codigo.R",
    fecha:  "2026"
  }

  /* ── Plantilla para el siguiente trabajo ──────────────────
  ,{
    id:          "nombre-sin-espacios",
    nombre:      "Título completo del trabajo",
    unidad:      "u1",         // "u1" o "u2"
    icono:       "📊",
    descripcion: "Descripción breve del análisis realizado.",
    pdf:         "trabajos/unidad1/carpeta-del-trabajo/analisis.pdf",
    codigo:      "trabajos/unidad1/carpeta-del-trabajo/codigo.R",
    fecha:       "2026"
  }
  ──────────────────────────────────────────────────────────── */
];

/* ═══════════ ESTADO ════════════════════════════════════════ */
let filtroActivo = "all";

/* ═══════════ REFERENCIAS DOM ══════════════════════════════ */
const gridEl   = document.getElementById("trabajos-grid");
const buscarEl = document.getElementById("buscador");
const emptyEl  = document.getElementById("emptyState");
const totalEl  = document.getElementById("totalTrabajos");
const u1El     = document.getElementById("u1c");
const u2El     = document.getElementById("u2c");
const heroEl   = document.getElementById("counterWorks");

/* ═══════════ ESTADÍSTICAS ══════════════════════════════════ */
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
  const iv = setInterval(() => {
    n++;
    el.textContent = n;
    if (n >= fin) clearInterval(iv);
  }, 60);
}

/* ═══════════ CREAR TARJETA ═════════════════════════════════ */
function crearTarjeta(t, delay) {
  const esU2   = t.unidad === "u2";
  const tagCls = esU2 ? "u2" : "";
  const tagTxt = esU2 ? "Unidad 2" : "Unidad 1";

  return `
<div class="trab-card reveal" style="animation-delay:${delay}ms">

  <div class="tc-header">
    <div>
      <span class="tc-unidad-tag ${tagCls}">${tagTxt}</span>
      <h3 class="tc-title" style="margin-top:10px">${t.nombre}</h3>
    </div>
    <div class="tc-ico">${t.icono}</div>
  </div>

  <p class="tc-desc">${t.descripcion}</p>
  <div class="tc-divider"></div>

  <div class="tc-acciones">

    <div>
      <div class="ac-label">Informe PDF</div>
      <div class="ac-row">
        <a href="${t.pdf}"
           target="_blank"
           rel="noopener noreferrer"
           class="btn-ac">
          📄 Ver PDF
        </a>
        <a href="${t.pdf}"
           download
           class="btn-ac btn-ac-dl">
          ⬇ Descargar PDF
        </a>
      </div>
    </div>

    <div>
      <div class="ac-label">Código Fuente (.R)</div>
      <div class="ac-row">
        <a href="${t.codigo}"
           target="_blank"
           rel="noopener noreferrer"
           class="btn-ac">
          💻 Ver Código
        </a>
        <a href="${t.codigo}"
           download
           class="btn-ac btn-ac-dl">
          ⬇ Descargar .R
        </a>
      </div>
    </div>

    ${t.fecha ? `<p class="tc-fecha">Entregado: ${t.fecha}</p>` : ""}
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
  gridEl.innerHTML = data.map((t, i) => crearTarjeta(t, i * 80)).join("");

  // Activar animación reveal en las tarjetas recién creadas
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
window.filtrar = filtrar; // exponer para onclick en HTML

function aplicar(tipo, texto) {
  let res = tipo === "all" ? trabajos : trabajos.filter(t => t.unidad === tipo);
  if (texto.trim()) {
    res = res.filter(t =>
      t.nombre.toLowerCase().includes(texto) ||
      t.descripcion.toLowerCase().includes(texto)
    );
  }
  mostrar(res);
}

/* ═══════════ BUSCADOR ══════════════════════════════════════ */
buscarEl?.addEventListener("input", e =>
  aplicar(filtroActivo, e.target.value.toLowerCase())
);

/* ═══════════ CARGAR INSIGNIAS ══════════════════════════════
   Se llama desde el atributo onchange del <input type="file">
   en el HTML. Carga la imagen localmente via FileReader.
   Para imágenes permanentes: ponlas en assets/ y cambia el
   src del <img> directamente en el HTML.
   ══════════════════════════════════════════════════════════ */
window.cargarInsignia = function(lado, input) {
  const file = input.files?.[0];
  if (!file) return;

  const reader = new FileReader();
  reader.onload = ev => {
    const imgId = lado === "izq" ? "imgIzq" : "imgDer";
    const phId  = lado === "izq" ? "phIzq"  : "phDer";
    const img   = document.getElementById(imgId);
    const ph    = document.getElementById(phId);

    if (img && ph) {
      img.src = ev.target.result;
      img.classList.remove("hidden");
      ph.style.display = "none";
    }
  };
  reader.readAsDataURL(file);
};

/* ═══════════ NAVBAR SCROLL ═════════════════════════════════ */
const navbarEl = document.getElementById("navbar");
window.addEventListener("scroll", () =>
  navbarEl?.classList.toggle("scrolled", window.scrollY > 55)
);

/* ═══════════ NAV LINK ACTIVO ═══════════════════════════════ */
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

/* ═══════════ REVEAL ON SCROLL ══════════════════════════════ */
const revObs = new IntersectionObserver(entries => {
  entries.forEach(e => { if (e.isIntersecting) e.target.classList.add("visible"); });
}, { threshold: 0.1 });

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

/* ═══════════ INICIAR ═══════════════════════════════════════ */
actualizarStats();
mostrar(trabajos);

// Aplicar reveal a cards estáticas tras carga completa
window.addEventListener("load", () => {
  document.querySelectorAll(".pcard, .tcard, .dstat").forEach(el => {
    el.classList.add("reveal");
    revObs.observe(el);
  });
});