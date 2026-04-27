/* ============================================================
   effects.js — Efectos visuales: estrellas, cursor, parallax
   ============================================================ */

/* ═══════════ STARFIELD ═════════════════════════════════════ */
(function () {
  const canvas = document.getElementById("starfield");
  if (!canvas) return;
  const ctx = canvas.getContext("2d");
  let W, H, stars;

  function resize() {
    W = canvas.width  = window.innerWidth;
    H = canvas.height = window.innerHeight;
  }

  function initStars(n = 200) {
    stars = Array.from({ length: n }, () => ({
      x:     Math.random() * W,
      y:     Math.random() * H,
      r:     Math.random() * 1.3 + 0.2,
      alpha: Math.random() * 0.55 + 0.1,
      speed: Math.random() * 0.012 + 0.003,
      dir:   Math.random() * Math.PI * 2
    }));
  }

  function draw() {
    ctx.clearRect(0, 0, W, H);

    /* Estrellas */
    stars.forEach(s => {
      ctx.beginPath();
      ctx.arc(s.x, s.y, s.r, 0, Math.PI * 2);
      ctx.fillStyle = `rgba(168,192,214,${s.alpha})`;
      ctx.fill();

      s.x += Math.cos(s.dir) * s.speed;
      s.y += Math.sin(s.dir) * s.speed;
      if (s.x < 0 || s.x > W) s.dir = Math.PI - s.dir;
      if (s.y < 0 || s.y > H) s.dir = -s.dir;

      s.alpha += (Math.random() - 0.5) * 0.007;
      s.alpha  = Math.max(0.05, Math.min(0.65, s.alpha));
    });

    /* Líneas de constelación */
    ctx.lineWidth = 0.5;
    for (let i = 0; i < stars.length; i++) {
      for (let j = i + 1; j < stars.length; j++) {
        const dx = stars[i].x - stars[j].x;
        const dy = stars[i].y - stars[j].y;
        const d  = Math.sqrt(dx * dx + dy * dy);
        if (d < 95) {
          ctx.globalAlpha = (1 - d / 95) * 0.18;
          ctx.strokeStyle = "rgba(56,189,248,1)";
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

  resize(); initStars(); draw();
  window.addEventListener("resize", () => { resize(); initStars(); });
})();

/* ═══════════ CURSOR ════════════════════════════════════════ */
(function () {
  const dot  = document.querySelector(".cursor-dot");
  const ring = document.querySelector(".cursor-ring");
  if (!dot || !ring) return;

  let mx = 0, my = 0, rx = 0, ry = 0;

  document.addEventListener("mousemove", e => {
    mx = e.clientX; my = e.clientY;
    dot.style.left = mx + "px";
    dot.style.top  = my + "px";
  });

  function animRing() {
    rx += (mx - rx) * 0.13;
    ry += (my - ry) * 0.13;
    ring.style.left = rx + "px";
    ring.style.top  = ry + "px";
    requestAnimationFrame(animRing);
  }
  animRing();

  function bindHover() {
    document.querySelectorAll("a, button, .fbtn, .ins-frame, .trab-card").forEach(el => {
      el.addEventListener("mouseenter", () => {
        dot.style.width  = dot.style.height  = "10px";
        ring.style.width = ring.style.height = "48px";
        ring.style.borderColor = "rgba(56,189,248,0.85)";
      });
      el.addEventListener("mouseleave", () => {
        dot.style.width  = dot.style.height  = "7px";
        ring.style.width = ring.style.height = "30px";
        ring.style.borderColor = "rgba(56,189,248,0.5)";
      });
    });
  }

  bindHover();
  const grid = document.getElementById("trabajos-grid");
  if (grid) new MutationObserver(bindHover).observe(grid, { childList: true });
  document.documentElement.style.cursor = "none";
})();

/* ═══════════ REVEAL ON SCROLL ══════════════════════════════ */
(function () {
  const els = document.querySelectorAll(
    ".pcard, .tcard, .dstat, .hcnt"
  );
  const obs = new IntersectionObserver(entries => {
    entries.forEach(e => {
      if (e.isIntersecting) {
        e.target.style.opacity   = "1";
        e.target.style.transform = "translateY(0)";
      }
    });
  }, { threshold: 0.12 });

  els.forEach((el, i) => {
    el.style.opacity   = "0";
    el.style.transform = "translateY(28px)";
    el.style.transition = `opacity .65s ease ${i * 0.07}s, transform .65s ease ${i * 0.07}s`;
    obs.observe(el);
  });
})();

/* ═══════════ PARALLAX SUAVE ════════════════════════════════ */
(function () {
  const glows = document.querySelectorAll(".hero-glow");
  if (!glows.length) return;
  window.addEventListener("scroll", () => {
    const s = window.scrollY;
    glows[0] && (glows[0].style.transform = `translateY(${s * 0.12}px)`);
    glows[1] && (glows[1].style.transform = `translateY(${-s * 0.08}px)`);
  });
})();