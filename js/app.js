const trabajos = [
  {
    nombre: "Bootstrap",
    unidad: "u1",
    tipo: "📄 PDF",
    link: "trabajos/unidad1/bootstrap.pdf"
  },
  {
    nombre: "Moran y Geary",
    unidad: "u1",
    tipo: "📄 PDF",
    link: "trabajos/unidad1/moran.pdf"
  },
  {
    nombre: "Análisis Espacial",
    unidad: "u2",
    tipo: "📄 PDF",
    link: "trabajos/unidad2/analisis.pdf"
  }
];

const contenedor = document.getElementById("trabajos");

function mostrar(data) {
  contenedor.innerHTML = "";

  data.forEach(t => {
    contenedor.innerHTML += `
      <div class="card">
        <h3>${t.nombre}</h3>
        <p>${t.tipo}</p>
        <a href="${t.link}" target="_blank">Abrir</a>
      </div>
    `;
  });

  document.getElementById("total").textContent = data.length;
}

function filtrar(tipo) {
  if (tipo === "all") {
    mostrar(trabajos);
  } else {
    mostrar(trabajos.filter(t => t.unidad === tipo));
  }
}

document.getElementById("buscador").addEventListener("input", e => {
  const texto = e.target.value.toLowerCase();
  const filtrados = trabajos.filter(t =>
    t.nombre.toLowerCase().includes(texto)
  );
  mostrar(filtrados);
});

mostrar(trabajos);