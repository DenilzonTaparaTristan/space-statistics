# ============================================================
# Práctica: Índice de Moran — Grilla 3x3 de quinua
# Denilzon Robinho Tapara Tristan
#Curso Estadística Espacial · FINESI-UNA Puno
# Métodos: Contigüidad Torre (rook) y Reina (queen)
# ============================================================

library(spdep)

# ------------------------------------------------------------
# 1. Datos: rendimiento (t/ha) de 9 celdas, fila por fila
# ------------------------------------------------------------
# Disposición visual de la grilla:
#   P1(2.1) P2(2.0) P3(1.6)
#   P4(1.9) P5(1.8) P6(1.5)
#   P7(1.7) P8(1.4) P9(1.3)

z <- c(2.1, 2.0, 1.6,
       1.9, 1.8, 1.5,
       1.7, 1.4, 1.3)

cat("Media:", mean(z), "t/ha\n")
cat("Denominador Σdᵢ²:", sum((z - mean(z))^2), "\n\n")

# ============================================================
# MÉTODO TORRE (rook): vecinos arriba/abajo/izquierda/derecha
# ============================================================

W_torre <- matrix(0, 9, 9)

# Vecinos horizontales (misma fila)
pares_h <- list(c(1,2), c(2,3), c(4,5), c(5,6), c(7,8), c(8,9))
# Vecinos verticales (misma columna)
pares_v <- list(c(1,4), c(4,7), c(2,5), c(5,8), c(3,6), c(6,9))

for (p in c(pares_h, pares_v)) {
  W_torre[p[1], p[2]] <- 1
  W_torre[p[2], p[1]] <- 1
}

cat("=== MÉTODO TORRE ===\n")
cat("Suma total W:", sum(W_torre), "\n")  # debe ser 24

lw_torre <- mat2listw(W_torre, style = "B")   # B = binaria sin estandarizar

# Índice de Moran manual verificado con spdep
I_torre <- moran(z, lw_torre, n = length(z), S0 = Szero(lw_torre))$I
cat("Índice de Moran Torre (debe ≈ 0.4875):", round(I_torre, 4), "\n\n")

# Prueba analítica (supuesto de normalidad)
cat("--- Prueba analítica (moran.test) ---\n")
mt_torre <- moran.test(z, lw_torre)
print(mt_torre)
# Interpretación:
#   Moran I statistic ≈ 0.4875
#   p-value < 0.05  →  rechazamos H0 de ausencia de autocorrelación
#   Conclusión: agrupamiento espacial significativo

# Prueba Monte Carlo (más robusta con n pequeño)
set.seed(2024)
cat("\n--- Prueba Monte Carlo (moran.mc, 999 permutaciones) ---\n")
mc_torre <- moran.mc(z, lw_torre, nsim = 999)
print(mc_torre)
# El p-value por permutaciones confirma el resultado analítico

# ============================================================
# MÉTODO REINA (queen): Torre + diagonales
# ============================================================

W_reina <- W_torre  # parte de la torre y agrega diagonales

pares_diag <- list(c(1,5), c(2,4), c(2,6), c(3,5),
                   c(4,8), c(5,7), c(5,9), c(6,8))

for (p in pares_diag) {
  W_reina[p[1], p[2]] <- 1
  W_reina[p[2], p[1]] <- 1
}

cat("\n=== MÉTODO REINA ===\n")
cat("Suma total W:", sum(W_reina), "\n")  # debe ser 40

lw_reina <- mat2listw(W_reina, style = "B")

I_reina <- moran(z, lw_reina, n = length(z), S0 = Szero(lw_reina))$I
cat("Índice de Moran Reina (debe ≈ 0.2850):", round(I_reina, 4), "\n\n")

cat("--- Prueba analítica (moran.test) ---\n")
mt_reina <- moran.test(z, lw_reina)
print(mt_reina)

set.seed(2024)
cat("\n--- Prueba Monte Carlo (moran.mc, 999 permutaciones) ---\n")
mc_reina <- moran.mc(z, lw_reina, nsim = 999)
print(mc_reina)

# ============================================================
# COMPARACIÓN Torre vs Reina con pesos estandarizados (style="W")
# ============================================================

cat("\n=== COMPARACIÓN con pesos estandarizados por fila (style='W') ===\n")
lw_t_W <- mat2listw(W_torre, style = "W")
lw_r_W <- mat2listw(W_reina, style = "W")

I_t_std <- moran(z, lw_t_W, n = length(z), S0 = Szero(lw_t_W))$I
I_r_std <- moran(z, lw_r_W, n = length(z), S0 = Szero(lw_r_W))$I

cat("I Torre  estandarizado:", round(I_t_std, 4), "\n")
cat("I Reina  estandarizado:", round(I_r_std, 4), "\n")
cat("Nota: con style='W' los valores cambian porque cada fila suma 1.\n")
cat("      Esta normalización es más común en datos reales.\n")
