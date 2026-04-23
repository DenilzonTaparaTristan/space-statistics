/* ============================================================
   effects.js — Efectos visuales: estrellas + cursor
   ============================================================ */

/* ===== STARFIELD ===== */
(function () {
  const canvas = document.getElementById("starfield");
  if (!canvas) return;

  const ctx    = canvas.getContext("2d");
  let W, H, stars;

  function resize() {
    W = canvas.width  = window.innerWidth;
    H = canvas.height = window.innerHeight;
  }

  function initStars(count = 180) {
    stars = Array.from({ length: count }, () => ({
      x:     Math.random() * W,
      y:     Math.random() * H,
      r:     Math.random() * 1.4 + 0.2,
      alpha: Math.random() * 0.6 + 0.1,
      speed: Math.random() * 0.015 + 0.003,
      dir:   Math.random() * Math.PI * 2
    }));
  }

  function draw() {
    ctx.clearRect(0, 0, W, H);

    stars.forEach(s => {
      ctx.beginPath();
      ctx.arc(s.x, s.y, s.r, 0, Math.PI * 2);
      ctx.fillStyle = `rgba(148,163,184,${s.alpha})`;
      ctx.fill();

      // Movimiento suave
      s.x += Math.cos(s.dir) * s.speed;
      s.y += Math.sin(s.dir) * s.speed;

      // Rebote en bordes
      if (s.x < 0 || s.x > W) s.dir = Math.PI - s.dir;
      if (s.y < 0 || s.y > H) s.dir = -s.dir;

      // Parpadeo
      s.alpha += (Math.random() - 0.5) * 0.008;
      s.alpha  = Math.max(0.05, Math.min(0.7, s.alpha));
    });

    // Líneas de constelación entre estrellas cercanas
    ctx.strokeStyle = "rgba(56,189,248,0.05)";
    ctx.lineWidth   = 0.5;

    for (let i = 0; i < stars.length; i++) {
      for (let j = i + 1; j < stars.length; j++) {
        const dx   = stars[i].x - stars[j].x;
        const dy   = stars[i].y - stars[j].y;
        const dist = Math.sqrt(dx * dx + dy * dy);

        if (dist < 100) {
          ctx.globalAlpha = (1 - dist / 100) * 0.2;
          ctx.beginPath();
          ctx.moveTo(stars[i].x, stars[i].y);
          ctx.lineTo(stars[j].x, stars[j].y);
          ctx.stroke();
        }
      }
    }

    ctx.globalAlpha = 1;
    requestAnimationFrame(draw);
  }

  resize();
  initStars();
  draw();
  window.addEventListener("resize", () => { resize(); initStars(); });
})();

/* ===== CURSOR PERSONALIZADO ===== */
(function () {
  const dot  = document.querySelector(".cursor-dot");
  const ring = document.querySelector(".cursor-ring");
  if (!dot || !ring) return;

  let mouseX = 0, mouseY = 0;
  let ringX  = 0, ringY  = 0;

  document.addEventListener("mousemove", e => {
    mouseX = e.clientX;
    mouseY = e.clientY;
    dot.style.left = mouseX + "px";
    dot.style.top  = mouseY + "px";
  });

  // Ring sigue con inercia
  function animateRing() {
    ringX += (mouseX - ringX) * 0.12;
    ringY += (mouseY - ringY) * 0.12;
    ring.style.left = ringX + "px";
    ring.style.top  = ringY + "px";
    requestAnimationFrame(animateRing);
  }
  animateRing();

  // Efecto hover en elementos interactivos
  const interactivos = document.querySelectorAll("a, button, .filter-btn, .insignia-card, .tema-card, .trabajo-card");

  function attachHover() {
    document.querySelectorAll("a, button, .filter-btn, .insignia-placeholder").forEach(el => {
      el.addEventListener("mouseenter", () => {
        dot.style.width  = "10px";
        dot.style.height = "10px";
        ring.style.width  = "50px";
        ring.style.height = "50px";
        ring.style.borderColor = "rgba(56,189,248,0.8)";
      });
      el.addEventListener("mouseleave", () => {
        dot.style.width  = "6px";
        dot.style.height = "6px";
        ring.style.width  = "32px";
        ring.style.height = "32px";
        ring.style.borderColor = "rgba(56,189,248,0.5)";
      });
    });
  }

  attachHover();

  // Re-aplicar cuando se renderizan tarjetas dinámicas
  const targetNode = document.getElementById("trabajos-grid");
  if (targetNode) {
    new MutationObserver(attachHover).observe(targetNode, { childList: true });
  }

  // Ocultar cursor nativo completamente
  document.documentElement.style.cursor = "none";
})();

/* ===== ANIMACIONES REVEAL AL SCROLL ===== */
(function () {
  const revealEls = document.querySelectorAll(
    ".perfil-card, .tema-card, .insignia-card, .dash-stat, .hero-stats-float .stat-float"
  );

  const obs = new IntersectionObserver(entries => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.style.opacity   = "1";
        entry.target.style.transform = "translateY(0)";
      }
    });
  }, { threshold: 0.15 });

  revealEls.forEach((el, i) => {
    el.style.opacity   = "0";
    el.style.transform = "translateY(30px)";
    el.style.transition = `opacity 0.7s ease ${i * 0.1}s, transform 0.7s ease ${i * 0.1}s`;
    obs.observe(el);
  });
})();

/* ===== PARALLAX SUAVE EN HERO ===== */
(function () {
  const orbEl = document.querySelector(".geo-orb");
  if (!orbEl) return;

  window.addEventListener("scroll", () => {
    const scrollY = window.scrollY;
    orbEl.style.transform = `translateY(${scrollY * 0.15}px)`;
  });
})();