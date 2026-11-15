library(tidyverse)
set.seed(42)
dir.create("figuras", showWarnings = FALSE)

df <- read_csv("data/clean/vuelos_limpio.csv", show_col_types = FALSE)

df <- df |>
  mutate(Internacional = toupper(trimws(`Pais Origen`)) != "COLOMBIA" |
                         toupper(trimws(`Pais Destino`)) != "COLOMBIA")

cat("NA en Internacional:", sum(is.na(df$Internacional)), "\n")

UMBRAL <- 0.80

d0 <- df |>
  filter(`Sillas Ofrecidas` > 0, !is.na(Internacional)) |>
  mutate(Ocupacion = `Pasajeros A Bordo` / `Sillas Ofrecidas`)

cat("Registros con sillas > 0:", nrow(d0), "\n")
cat("Registros con ocupación > 1 (excluidos):", sum(d0$Ocupacion > 1, na.rm = TRUE), "\n")

d <- d0 |>
  filter(Ocupacion <= 1) |>
  mutate(Alta = Ocupacion > UMBRAL)

N <- nrow(d)
cat("N final (espacio muestral):", N, "\n")

nA   <- sum(d$Internacional)
nB   <- sum(d$Alta)
nAB  <- sum(d$Internacional & d$Alta)
nAc  <- N - nA
nAcB <- sum(!d$Internacional & d$Alta)

P_A         <- nA / N
P_B         <- nB / N
P_AB        <- nAB / N
P_B_dado_A  <- nAB / nA
P_B_dado_Ac <- nAcB / nAc

eventos <- tibble(
  medida = c("P(A)", "P(B)", "P(A ∩ B)", "P(A)·P(B)",
             "P(B | A)", "P(B | no A)"),
  valor  = c(P_A, P_B, P_AB, P_A * P_B, P_B_dado_A, P_B_dado_Ac)
)
print(eventos)

cat("\nP(A∩B) =", P_AB, " vs  P(A)P(B) =", P_A * P_B, "\n")
print(chisq.test(table(d$Internacional, d$Alta)))

cat("\nP(B) por prob. total:", P_B_dado_A * P_A + P_B_dado_Ac * (1 - P_A),
    " | P(B) directa:", P_B, "\n")

P_A_dado_B_bayes   <- P_B_dado_A * P_A / P_B
P_A_dado_B_directo <- nAB / nB

cat("\nBayes:  P(A|B) =", P_A_dado_B_bayes, "\n")
cat("Directo n(A∩B)/n(B) =", P_A_dado_B_directo, "\n")
stopifnot(isTRUE(all.equal(P_A_dado_B_bayes, P_A_dado_B_directo)))

por_internacional <- d |>
  group_by(Internacional) |>
  summarise(n = n(), P_alta = mean(Alta), .groups = "drop")
print(por_internacional)

por_tipo_vuelo <- d |>
  group_by(`Tipo Vuelo`) |>
  summarise(n = n(), P_alta = mean(Alta), .groups = "drop")
print(por_tipo_vuelo)

por_trafico <- d |>
  group_by(`Tráfico`) |>
  summarise(n = n(), P_alta = mean(Alta), .groups = "drop")
print(por_trafico)

U75 <- quantile(d$Ocupacion, 0.75)
cat("\nPercentil 75 de ocupación:", U75, "\n")
cat("P(B75 | A)  =", mean(d$Ocupacion[d$Internacional] > U75), "\n")
cat("P(B75 | no A) =", mean(d$Ocupacion[!d$Internacional] > U75), "\n")

g1 <- por_internacional |>
  mutate(Tipo = if_else(Internacional, "Internacional", "Nacional")) |>
  ggplot(aes(Tipo, P_alta)) +
  geom_col() +
  labs(title = paste0("P(ocupación > ", UMBRAL * 100, "%) según tipo de ruta"),
       x = "Tipo de ruta", y = "Probabilidad")
ggsave("figuras/p5_prob_ocupacion_alta.png", g1, width = 6, height = 4, dpi = 150)

x <- df$`Pasajeros A Bordo`
x <- x[!is.na(x)]

mu    <- mean(x)
sigma <- sqrt(mean((x - mu)^2))
asim  <- mean((x - mu)^3) / sigma^3

cat("\nPoblación: N =", length(x), " mu =", mu, " sigma =", sigma,
    " asimetría =", asim, " ceros =", sum(x == 0), "\n")

q <- quantile(x, c(0.25, 0.5, 0.75))
iqr <- q[3] - q[1]
cat("Mediana:", q[2], " Q1:", q[1], " Q3:", q[3], " RIC:", iqr,
    " máximo:", max(x), "\n")
cat("Atípicos (> Q3 + 1.5·RIC):", sum(x > q[3] + 1.5 * iqr),
    sprintf("(%.1f%% de los registros)\n", 100 * mean(x > q[3] + 1.5 * iqr)))
cat("Proporción de registros con <= 10 pasajeros:", mean(x <= 10), "\n")

g_pob <- ggplot(tibble(x), aes(x + 1)) +
  geom_histogram(bins = 50) +
  scale_x_log10() +
  labs(title = "Distribución de pasajeros a bordo por registro (escala log)",
       x = "Pasajeros a bordo + 1", y = "Frecuencia")
ggsave("figuras/tlc_poblacion.png", g_pob, width = 7, height = 4, dpi = 150)

ns <- c(2, 5, 30, 100, 500, 1000)
B  <- 2000

medias <- map_dfr(ns, \(n) {
  tibble(n = n, media = replicate(B, mean(sample(x, n, replace = TRUE))))
})

resumen <- medias |>
  group_by(n) |>
  summarise(media_de_medias = mean(media),
            sd_de_medias    = sd(media),
            asimetria_medias = mean((media - mean(media))^3) / sd(media)^3,
            .groups = "drop") |>
  mutate(mu = mu, sd_teorica = sigma / sqrt(n))
print(resumen)

curvas <- map_dfr(ns, \(n) {
  se <- sigma / sqrt(n)
  tibble(n = n, media = seq(mu - 4 * se, mu + 4 * se, length.out = 300)) |>
    mutate(dens = dnorm(media, mu, se))
})

g_tlc <- ggplot(medias, aes(media)) +
  geom_histogram(aes(y = after_stat(density)), bins = 40) +
  geom_line(data = curvas, aes(y = dens), linewidth = 0.8) +
  geom_vline(xintercept = mu, linetype = "dashed") +
  facet_wrap(~n, scales = "free", labeller = label_both) +
  labs(title = paste0("TLC: distribución de la media muestral (B = ", B, ")"),
       subtitle = "Línea: N(mu, sigma/sqrt(n)); punteada: mu poblacional",
       x = "Media muestral de pasajeros a bordo", y = "Densidad")
ggsave("figuras/tlc_medias.png", g_tlc, width = 9, height = 6, dpi = 150)
