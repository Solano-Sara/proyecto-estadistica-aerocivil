
# R/temporal_correlacion.R  -  Persona B
# Pregunta 2: caída/recuperación del tráfico (2a) y temporadas (2b)
# Pregunta 3: asociación entre sillas ofrecidas, vuelos y pasajeros
# Ley de los Grandes Números (LGN)
# Resultados: tablas/ y figuras/ (prefijos p2_, p3_ y lgn_)

library(tidyverse)
library(lubridate)

set.seed(42)
dir.create("figuras", showWarnings = FALSE)
dir.create("tablas",  showWarnings = FALSE)


# 0. Datos: mismas definiciones que cargaDatos.R (solo se crean si no existen)

if (!all(c("df_pax", "df_occ", "df_temp") %in% ls())) {
  df <- read_csv("data/aerocivil_trafico.csv", show_col_types = FALSE)
  df_pax  <- df |> filter(!is.na(`Pasajeros A Bordo`))
  df_occ  <- df_pax |>
    filter(`Sillas Ofrecidas` > 0) |>
    mutate(Ocupacion = `Pasajeros A Bordo` / `Sillas Ofrecidas`)
  df_temp <- df_pax |> filter(Año %in% 2022:2025)
}

meses_es <- c("ene", "feb", "mar", "abr", "may", "jun",
              "jul", "ago", "sep", "oct", "nov", "dic")


# PREGUNTA 2a: caída y recuperación (df_pax)

mensual <- df_pax |>
  group_by(Año, Mes) |>
  summarise(pasajeros = sum(`Pasajeros A Bordo`),
            vuelos    = sum(`Número de Vuelos`),
            .groups = "drop") |>
  mutate(fecha = make_date(Año, Mes, 1)) |>
  arrange(fecha)

# Línea base: promedio mensual de enero-febrero de 2020
base <- mensual |>
  filter(Año == 2020, Mes %in% 1:2) |>
  summarise(pax = mean(pasajeros), vuelos = mean(vuelos))

mensual <- mensual |>
  mutate(ind_pax    = pasajeros / base$pax    * 100,
         ind_vuelos = vuelos    / base$vuelos * 100)
write_csv(mensual, "tablas/p2_serie_mensual.csv")

# Primer mes desde el cual el índice se mantiene >= 100 durante k meses seguidos
primer_mes_sostenido <- function(fecha, indice, k = 3) {
  ok <- indice >= 100
  for (i in seq_len(length(ok) - k + 1)) {
    if (all(ok[i:(i + k - 1)])) return(fecha[i])
  }
  as.Date(NA)
}

resumir <- function(col_abs, col_ind, nombre) {
  i_min <- which.min(mensual[[col_abs]])
  post  <- mensual |> filter(fecha > mensual$fecha[i_min])
  tibble(variable = nombre,
         base_mensual = if (col_abs == "pasajeros") base$pax else base$vuelos,
         mes_minimo = mensual$fecha[i_min],
         valor_minimo = mensual[[col_abs]][i_min],
         caida_maxima_pct = 100 - mensual[[col_ind]][i_min],
         primer_mes_100 = post$fecha[which(post[[col_ind]] >= 100)[1]],
         primer_mes_sostenido_3m = primer_mes_sostenido(post$fecha, post[[col_ind]]))
}

resumen_recuperacion <- bind_rows(
  resumir("pasajeros", "ind_pax",    "Pasajeros a bordo"),
  resumir("vuelos",    "ind_vuelos", "Número de vuelos")
)
print(resumen_recuperacion)
write_csv(resumen_recuperacion, "tablas/p2_resumen_recuperacion.csv")

# Resumen anual (2026 llega solo hasta junio)
resumen_anual <- mensual |>
  group_by(Año) |>
  summarise(meses = n(),
            pasajeros_total = sum(pasajeros),
            pasajeros_prom_mensual = mean(pasajeros),
            indice_prom_pax = mean(ind_pax),
            indice_prom_vuelos = mean(ind_vuelos),
            .groups = "drop")
print(resumen_anual)
write_csv(resumen_anual, "tablas/p2_resumen_anual.csv")

# Gráfico: pasajeros por mes
g_serie <- ggplot(mensual, aes(fecha, pasajeros)) +
  geom_line(linewidth = 0.8, color = "steelblue") +
  geom_point(size = 1, color = "steelblue") +
  scale_y_continuous(labels = scales::label_number(scale = 1e-6, suffix = " M")) +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
  labs(title = "Pasajeros a bordo por mes (2020-2026)",
       x = "Año", y = "Pasajeros (millones)",
       caption = "Fuente: Aerocivil. 2026 hasta junio.") +
  theme_minimal()
ggsave("figuras/p2_serie_mensual.png", g_serie, width = 9, height = 5, dpi = 300)

# Gráfico: índice de recuperación (pasajeros y vuelos)
g_ind <- mensual |>
  pivot_longer(c(ind_pax, ind_vuelos), names_to = "serie", values_to = "indice") |>
  mutate(serie = recode(serie, ind_pax = "Pasajeros", ind_vuelos = "Vuelos")) |>
  ggplot(aes(fecha, indice, color = serie)) +
  geom_hline(yintercept = 100, linetype = "dashed") +
  geom_line(linewidth = 0.8) +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
  labs(title = "Índice de recuperación del tráfico aéreo",
       subtitle = "Base 100 = promedio mensual de enero-febrero de 2020",
       x = "Año", y = "Índice (base = 100)", color = NULL,
       caption = "Fuente: Aerocivil. 2026 hasta junio.") +
  theme_minimal()
ggsave("figuras/p2_indice_recuperacion.png", g_ind, width = 9, height = 5, dpi = 300)


# PREGUNTA 2b: temporadas alta y baja (df_temp, 2022-2025)

# Los percentiles se calculan DENTRO de cada año (12 meses): así el crecimiento
# del tráfico entre 2022 y 2025 no hace que los últimos años parezcan "altos".
estac_anual <- df_temp |>
  group_by(Año, Mes) |>
  summarise(pasajeros = sum(`Pasajeros A Bordo`), .groups = "drop") |>
  group_by(Año) |>
  mutate(p75 = quantile(pasajeros, 0.75),
         p25 = quantile(pasajeros, 0.25),
         alta = pasajeros > p75,
         baja = pasajeros < p25,
         indice = pasajeros / mean(pasajeros)) |>   # 1 = promedio mensual del año
  ungroup()

min_anios <- 3   # un mes es de temporada alta/baja si lo es en >= 3 de los 4 años

estacionalidad <- estac_anual |>
  group_by(Mes) |>
  summarise(anios_alta = sum(alta), anios_baja = sum(baja),
            indice_medio = mean(indice), sd_indice = sd(indice),
            .groups = "drop") |>
  mutate(temporada = case_when(anios_alta >= min_anios ~ "Alta",
                               anios_baja >= min_anios ~ "Baja",
                               TRUE ~ "Intermedia"),
         mes_nombre = factor(meses_es[Mes], levels = meses_es))
print(estacionalidad)
write_csv(estacionalidad, "tablas/p2_estacionalidad.csv")

g_est <- ggplot(estacionalidad, aes(mes_nombre, indice_medio, fill = temporada)) +
  geom_col() +
  geom_hline(yintercept = 1, linetype = "dashed") +
  scale_fill_manual(values = c(Alta = "#c0392b", Intermedia = "grey70", Baja = "#2980b9")) +
  labs(title = "Índice estacional del tráfico de pasajeros (2022-2025)",
       subtitle = "1 = promedio mensual del año. Alta/Baja: sobre P75 / bajo P25 en al menos 3 de 4 años",
       x = "Mes", y = "Índice estacional", fill = "Temporada",
       caption = "Fuente: Aerocivil") +
  theme_minimal()
ggsave("figuras/p2_estacionalidad.png", g_est, width = 8, height = 5, dpi = 300)

g_est_anios <- ggplot(estac_anual, aes(Mes, pasajeros, color = factor(Año))) +
  geom_line(linewidth = 0.8) +
  scale_x_continuous(breaks = 1:12, labels = meses_es) +
  scale_y_continuous(labels = scales::label_number(scale = 1e-6, suffix = " M")) +
  labs(title = "Pasajeros por mes en cada año completo (2022-2025)",
       x = "Mes", y = "Pasajeros (millones)", color = "Año",
       caption = "Fuente: Aerocivil") +
  theme_minimal()
ggsave("figuras/p2_estacionalidad_anios.png", g_est_anios, width = 8, height = 5, dpi = 300)


# PREGUNTA 3: sillas ofrecidas, vuelos y pasajeros (df_occ: sillas > 0)

vars_q3 <- df_occ |>
  select(sillas = `Sillas Ofrecidas`, vuelos = `Número de Vuelos`,
         pasajeros = `Pasajeros A Bordo`)

mensual_occ <- df_occ |>
  group_by(Año, Mes) |>
  summarise(sillas = sum(`Sillas Ofrecidas`), vuelos = sum(`Número de Vuelos`),
            pasajeros = sum(`Pasajeros A Bordo`), .groups = "drop") |>
  select(sillas, vuelos, pasajeros)

cor_tab <- function(d, metodo, etiqueta) {
  as_tibble(cor(d, method = metodo), rownames = "variable") |>
    mutate(metodo = etiqueta, .before = 1)
}

tabla_cor <- bind_rows(
  cor_tab(vars_q3,        "pearson",  "Pearson (registros)"),
  cor_tab(vars_q3,        "spearman", "Spearman (registros)"),
  cor_tab(log1p(vars_q3), "pearson",  "Pearson sobre log(1+x) (registros)"),
  cor_tab(mensual_occ,    "pearson",  "Pearson (totales mensuales)")
)
print(tabla_cor)
write_csv(tabla_cor, "tablas/p3_correlaciones.csv")

# Regresión simple pasajeros ~ sillas
modelo <- lm(pasajeros ~ sillas, data = vars_q3)
regresion <- tibble(n_registros = nrow(vars_q3),
                    intercepto = unname(coef(modelo)[1]),
                    pendiente  = unname(coef(modelo)[2]),
                    r2 = summary(modelo)$r.squared)
print(regresion)
write_csv(regresion, "tablas/p3_regresion.csv")

# ¿La ocupación depende del tamaño del registro? (Spearman)
tamano_vs_ocup <- tibble(
  ocup_vs_sillas = cor(df_occ$Ocupacion, df_occ$`Sillas Ofrecidas`, method = "spearman"),
  ocup_vs_vuelos = cor(df_occ$Ocupacion, df_occ$`Número de Vuelos`, method = "spearman"))
print(tamano_vs_ocup)
write_csv(tamano_vs_ocup, "tablas/p3_ocupacion_vs_tamano.csv")

# Diagramas de dispersión (escala log; se omiten los registros con 0)
dispersion <- function(x, y, xlab, ylab, titulo, archivo) {
  g <- vars_q3 |>
    filter(.data[[x]] > 0, .data[[y]] > 0) |>
    ggplot(aes(.data[[x]], .data[[y]])) +
    geom_bin2d(bins = 60) +
    scale_x_log10(labels = scales::label_comma()) +
    scale_y_log10(labels = scales::label_comma()) +
    scale_fill_viridis_c(trans = "log10", name = "Registros") +
    labs(title = titulo, x = xlab, y = ylab,
         caption = "Escala logarítmica; se omiten registros con 0 en alguna variable. Fuente: Aerocivil") +
    theme_minimal()
  ggsave(archivo, g, width = 8, height = 5.5, dpi = 300)
}
dispersion("sillas", "pasajeros", "Sillas ofrecidas", "Pasajeros a bordo",
           "Pasajeros vs. sillas ofrecidas por registro", "figuras/p3_pasajeros_vs_sillas.png")
dispersion("vuelos", "pasajeros", "Número de vuelos", "Pasajeros a bordo",
           "Pasajeros vs. número de vuelos por registro", "figuras/p3_pasajeros_vs_vuelos.png")
dispersion("vuelos", "sillas", "Número de vuelos", "Sillas ofrecidas",
           "Sillas ofrecidas vs. número de vuelos por registro", "figuras/p3_sillas_vs_vuelos.png")


# LEY DE LOS GRANDES NÚMEROS (df_pax, Pasajeros A Bordo por registro)

x     <- df_pax$`Pasajeros A Bordo`
mu    <- mean(x)
sigma <- sd(x)
cat("\nLGN: N =", length(x), " mu =", round(mu, 2), " sigma =", round(sigma, 2),
    " mediana =", median(x), " % ceros =", round(mean(x == 0) * 100, 1), "\n")

ns    <- c(10, 50, 100, 500, 1000, 5000, 10000, 50000, 100000)
n_rep <- 200   # réplicas por tamaño de muestra (para ver el error típico)

lgn_tabla <- map_dfr(ns, function(n) {
  medias <- replicate(n_rep, mean(sample(x, n)))
  tibble(n = n,
         media_una_muestra = medias[1],
         error_rel_una_muestra_pct = abs(medias[1] - mu) / mu * 100,
         error_rel_medio_pct = mean(abs(medias - mu)) / mu * 100,
         desv_est_de_medias = sd(medias))
}) |> mutate(media_poblacional = mu, .after = n)
print(lgn_tabla)
write_csv(lgn_tabla, "tablas/lgn_tabla.csv")

# Trayectorias de la media acumulada (3 corridas)
n_max <- 100000
trayectorias <- map_dfr(1:3, function(k) {
  idx <- sample(length(x), n_max)
  tibble(corrida = factor(k), n = 1:n_max, media_acum = cumsum(x[idx]) / (1:n_max))
})
g_lgn <- ggplot(trayectorias, aes(n, media_acum, color = corrida)) +
  geom_line(alpha = 0.8) +
  geom_hline(yintercept = mu, linetype = "dashed") +
  scale_x_log10(labels = scales::label_comma()) +
  labs(title = "Ley de los Grandes Números: media muestral acumulada",
       subtitle = "Pasajeros a bordo por registro; línea punteada = media poblacional",
       x = "Tamaño de muestra n (escala log)", y = "Media muestral (pasajeros)",
       color = "Corrida", caption = "Fuente: Aerocivil") +
  theme_minimal()
ggsave("figuras/lgn_trayectorias.png", g_lgn, width = 8, height = 5, dpi = 300)

g_err <- ggplot(lgn_tabla, aes(n, error_rel_medio_pct)) +
  geom_line(color = "steelblue") + geom_point(color = "steelblue") +
  scale_x_log10(labels = scales::label_comma()) +
  labs(title = "Error relativo medio de la media muestral según n",
       subtitle = paste0("Promedio de ", n_rep, " muestras por cada n"),
       x = "Tamaño de muestra n (escala log)", y = "Error relativo medio (%)",
       caption = "Fuente: Aerocivil") +
  theme_minimal()
ggsave("figuras/lgn_error_relativo.png", g_err, width = 8, height = 5, dpi = 300)

message("Listo: revisa tablas/ y figuras/")

library(tidyverse)
print(read_csv("tablas/lgn_tabla.csv"), width = Inf)
print(read_csv("tablas/p2_resumen_recuperacion.csv"), width = Inf)
print(read_csv("tablas/p2_resumen_anual.csv"), width = Inf)
