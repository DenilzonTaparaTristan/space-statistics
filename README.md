Space Statistics — Portafolio Académico
Denilzon Robinho Tapara Tristan | Estadística e Informática | UNA Puno
Curso: Estadística Espacial | Docente: Fred Torres Cruz | Período 2026

📁 Estructura del Proyecto
space-statistics/
│
├── index.html              ← Página principal
│
├── css/
│   └── styles.css          ← Todos los estilos
│
├── js/
│   ├── app.js              ← Lógica principal (trabajos, filtros, búsqueda)
│   └── effects.js          ← Efectos visuales (estrellas, cursor, animaciones)
│
├── assets/
│   ├── facultad.png        ← (opcional) Insignia de la facultad
│   └── universidad.png     ← (opcional) Insignia de la universidad
│
└── trabajos/
    ├── unidad1/
    │   └── analisis-espacial-ENA/
    │       ├── analisis.pdf
    │       └── codigo.R
    └── unidad2/
        └── (próximos trabajos)

➕ Cómo Agregar un Nuevo Trabajo

Sube los archivos a GitHub en la carpeta correspondiente:

   trabajos/unidad1/nombre-del-trabajo/
   ├── analisis.pdf
   └── codigo.R

Agrega el trabajo al array en js/app.js:

javascript   const trabajos = [
     // Trabajos existentes...
     {
       id: "nombre-unico",
       nombre: "Título del Trabajo",
       unidad: "u1",          // "u1" para Unidad 1, "u2" para Unidad 2
       icono: "📊",           // Emoji representativo
       descripcion: "Descripción breve del trabajo...",
       pdf: "trabajos/unidad1/nombre-del-trabajo/analisis.pdf",
       codigo: "trabajos/unidad1/nombre-del-trabajo/codigo.R",
       fecha: "2026"
     }
   ];

Commit y push a GitHub — el sitio se actualizará automáticamente.


❗ Solución al Problema de Archivos (404)
El error al abrir los archivos desde GitHub Pages se debe a que:

La carpeta en el repo se llama analisis-espacial-ENA pero la ruta en el código era analisis-espacial/analisis.pdf

Solución aplicada: El path correcto ahora es:
trabajos/unidad1/analisis-espacial-ENA/analisis.pdf
trabajos/unidad1/analisis-espacial-ENA/codigo.R
Verifica que los archivos existen exactamente en esas rutas en tu repositorio.

🖼️ Insignias Institucionales
Las insignias se pueden cargar de dos formas:
Opción 1 — Dinámico (desde el navegador):
Haz clic en el área de insignia en la sección "Insignias" y selecciona una imagen.
Opción 2 — Estático (recomendado para producción):

Coloca las imágenes en assets/facultad.png y assets/universidad.png
En index.html, reemplaza el <div class="insignia-placeholder"> por:

html   <img src="assets/facultad.png" class="insignia-img" alt="Insignia Facultad">

🚀 Deploy en GitHub Pages

Ve a Settings → Pages en tu repositorio
Selecciona la rama main y carpeta / (root)
El sitio estará en: https://denilzontaparatristan.github.io/space-statistics/