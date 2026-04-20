const trabajos = [
  {
    nombre: "Análisis Espacial de Cultivos Cosechados",
    unidad: "u1",
    descripcion: "Estudio basado en el Censo Nacional Agropecuario (ENA 2014-2024), analizando producción, venta y consumo de cultivos cosechados en unidades agropecuarias del Perú.",
    pdf: "trabajos/unidad1/analisis-espacial/analisis.pdf",
    codigo: "trabajos/unidad1/analisis-espacial/codigo.R"
  }
];

const contenedor = document.getElementById("trabajos");

function mostrar(data) {
  contenedor.innerHTML = "";

  data.forEach(t => {
    contenedor.innerHTML += `
      <div class="card trabajo-pro">
        <h3>${t.nombre}</h3>

        <p class="desc">${t.descripcion}</p>

        <div class="botones">
          <a href="${t.pdf}" target="_blank">📄 Ver PDF</a>
          <a href="${t.pdf}" download>⬇ Descargar PDF</a>
        </div>

        <div class="botones">
          <a href="${t.codigo}" target="_blank">💻 Ver Código</a>
          <a href="${t.codigo}" download>⬇ Descargar Código</a>
        </div>
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