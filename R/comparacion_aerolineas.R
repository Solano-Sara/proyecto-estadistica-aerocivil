#Preparación de datos
library(tidyverse)

dir.create("figuras", showWarnings = FALSE)
dir.create("tablas", showWarnings = FALSE)

nrow(df_occ_reg)

#Debido a que vcc dejo de operar en 2023, se decidio no tomarla en cuenta para este analisis
df_occ_reg |>
  group_by(`Sigla Empresa`, Nombre) |>
  summarise(pasajeros = sum(`Pasajeros A Bordo`),
            meses = n_distinct(Año, Mes),
            ultimo_año = max(Año),
            .groups = "drop") |>
  filter(ultimo_año == 2026, meses >= 60) |>
  arrange(desc(pasajeros)) |>
  slice_head(n = 6)

#Crear un daraset con las 5 aerolineas con más pasajeros

aerolineas_p1 <- c("AVA", "ARE", "RPB", "CMP", "EFY")
df_p1 <- df_occ_reg |> filter(`Sigla Empresa` %in% aerolineas_p1)

#Agregar nombres para el uso de boxplots
df_p1 <- df_p1 |>
  mutate(Aerolinea = recode(`Sigla Empresa`,
                            AVA = "Avianca", ARE = "Aires", RPB = "AeroRepública",
                            CMP = "Copa", EFY = "Easyfly"))

#
##
#EFY con meses extra / tiene operaciones en algunas rutas en pandemia, con numeros bajos de pasajeros
df_p1 |>
  filter(`Sigla Empresa` == "EFY", Año == 2020, Mes %in% 4:8) |>
  count(Mes)

df_p1 |>
  distinct(`Sigla Empresa`, Año, Mes) |>
  count(`Sigla Empresa`, name = "meses_con_datos")

df_p1 |>
  filter(`Sigla Empresa` == "EFY", Año == 2020, Mes %in% 7:8) |>
  select(Mes, Origen, Destino, `Número de Vuelos`, `Sillas Ofrecidas`,
         `Pasajeros A Bordo`, Ocupacion)

#indicador del tamaño de los aviones (promedio de sillas por vuelo de cada aerolínea)
df_p1 |>
  group_by(Aerolinea) |>
  summarise(sillas_por_vuelo = round(sum(`Sillas Ofrecidas`) / sum(`Número de Vuelos`), 1))
#
##
#

#--- Analisis ----

#  **Registros por aerolinea (fecuencias)**
tabla_freq <- df_p1 |>
  count(`Sigla Empresa`, name = "fa") |>
  arrange(desc(fa)) |>
  mutate(fr = round(fa / sum(fa), 4),
         fa_acum = cumsum(fa),
         fr_acum = round(cumsum(fr), 4))
tabla_freq

#Ocupacion por aerolinea
df_p1 <- df_p1 |>
  mutate(clase_ocup = cut(Ocupacion,
                          breaks = c(0, 0.5, 0.6, 0.7, 0.8, 0.9, 1),
                          include.lowest = TRUE))

# Frecuencias absolutas
table(df_p1$`Sigla Empresa`, df_p1$clase_ocup)

# Frecuencias relativas dentro de cada aerolínea
round(prop.table(table(df_p1$`Sigla Empresa`, df_p1$clase_ocup), margin = 1), 3)

#    **Tendencia central y dispersion**
moda <- function(x) {
  x <- round(x, 2)
  as.numeric(names(sort(table(x), decreasing = TRUE))[1])
}

resumen <- df_p1 |>
  group_by(`Sigla Empresa`) |>
  summarise(
    n         = n(),
    media     = mean(Ocupacion),
    mediana   = median(Ocupacion),
    moda      = moda(Ocupacion),
    minimo    = min(Ocupacion),
    maximo    = max(Ocupacion),
    rango     = maximo - minimo,
    varianza  = var(Ocupacion),
    desv_est  = sd(Ocupacion),
    Q1        = quantile(Ocupacion, 0.25),
    Q3        = quantile(Ocupacion, 0.75),
    RIC       = IQR(Ocupacion),
    P10       = quantile(Ocupacion, 0.10),
    P90       = quantile(Ocupacion, 0.90),
    .groups = "drop"
  ) |>
  arrange(desc(mediana)) |>
  mutate(across(where(is.numeric) & !n, ~ round(.x, 3)))

resumen
write_csv(resumen, "tablas/resumen_ocupacion_aerolineas.csv")

#Ocupacion ponderada (total de pasajeros sobre el total de sillas)
df_p1 |>
  group_by(`Sigla Empresa`) |>
  summarise(ocup_ponderada = round(sum(`Pasajeros A Bordo`) / sum(`Sillas Ofrecidas`), 3))

#
## Graficos
#

# Boxplot por aerolínea, ordenado por mediana
g_box <- ggplot(df_p1, aes(x = fct_reorder(Aerolinea, Ocupacion, median),
                           y = Ocupacion)) +
  geom_boxplot(fill = "steelblue", alpha = 0.6, outlier.alpha = 0.3) +
  labs(title = "Factor de ocupación por aerolínea (vuelos regulares)",
       x = "Aerolínea",
       y = "Ocupación (pasajeros / sillas ofrecidas)") +
  theme_minimal()
g_box
ggsave("figuras/p1_boxplot_ocupacion.png", g_box, width = 8, height = 5, dpi = 300)


# Histogramas por aerolínea
g_hist <- ggplot(df_p1, aes(x = Ocupacion, y = after_stat(density))) +
  geom_histogram(bins = 30, fill = "steelblue", color = "white") +
  facet_wrap(~ Aerolinea) +
  labs(title = "Distribución de la ocupación por aerolínea (vuelos regulares)",
       x = "Ocupación (pasajeros / sillas ofrecidas)",
       y = "Densidad") +
  theme_minimal()
g_hist
ggsave("figuras/p1_histogramas_ocupacion.png", g_hist, width = 9, height = 6, dpi = 300)



#
## Datos atipicos
#

# 1. Crear los límites y la columna atipico
df_p1 <- df_p1 |>
  group_by(`Sigla Empresa`) |>
  mutate(Q1 = quantile(Ocupacion, 0.25),
         Q3 = quantile(Ocupacion, 0.75),
         RIC = Q3 - Q1,
         lim_inf = Q1 - 1.5 * RIC,
         lim_sup = Q3 + 1.5 * RIC,
         atipico = case_when(Ocupacion < lim_inf ~ "bajo",
                             Ocupacion > lim_sup ~ "alto",
                             TRUE ~ "no")) |>
  ungroup()

#RIC
resumen |> select(`Sigla Empresa`, Q1, Q3, RIC, P10, P90)

# 3. Límites de atípicos por aerolínea
df_p1 |>
  group_by(Aerolinea) |>
  summarise(Q1 = first(Q1), Q3 = first(Q3), RIC = first(RIC),
            lim_inf = round(first(lim_inf), 3),
            lim_sup = round(first(lim_sup), 3))

# 4. Conteo y porcentaje de atípicos por aerolínea
df_p1 |>
  group_by(`Sigla Empresa`) |>
  summarise(n = n(),
            atipicos_bajos = sum(atipico == "bajo"),
            atipicos_altos = sum(atipico == "alto"),
            pct_atipicos = round(100 * mean(atipico != "no"), 2))

# 5. Algunos atípicos bajos
df_p1 |>
  filter(atipico == "bajo") |>
  select(Año, Mes, `Sigla Empresa`, Origen, Destino, `Número de Vuelos`,
         `Sillas Ofrecidas`, `Pasajeros A Bordo`, Ocupacion) |>
  arrange(Ocupacion) |>
  head(15)

# 6. Atípicos bajos por año
df_p1 |> filter(atipico == "bajo") |> count(Año)

# 7. ¿Los atípicos bajos son registros de 1 o 2 vuelos?
df_p1 |>
  filter(atipico == "bajo") |>
  summarise(n_atipicos_bajos = n(),
            pct_1_2_vuelos = round(100 * mean(`Número de Vuelos` <= 2), 1))

# Para comparar: registros NO atípicos
df_p1 |>
  filter(atipico == "no") |>
  summarise(n_normales = n(),
            pct_1_2_vuelos = round(100 * mean(`Número de Vuelos` <= 2), 1))

# Por aerolínea
df_p1 |>
  group_by(Aerolinea) |>
  summarise(pct_1_2_vuelos_atipicos = round(100 * mean(`Número de Vuelos`[atipico == "bajo"] <= 2), 1),
            pct_1_2_vuelos_normales = round(100 * mean(`Número de Vuelos`[atipico == "no"] <= 2), 1))

#
## Comparaciones por pares
#

pw <- pairwise.wilcox.test(df_p1$Ocupacion, df_p1$Aerolinea,
                           p.adjust.method = "bonferroni")
pw

# Diferencias de medianas (fila menos columna)
medianas <- df_p1 |>
  group_by(Aerolinea) |>
  summarise(mediana = median(Ocupacion))

outer(setNames(medianas$mediana, medianas$Aerolinea),
      setNames(medianas$mediana, medianas$Aerolinea), "-") |>
  round(3)

#
## Prueba Kruskal-Wallis
#

kruskal.test(Ocupacion ~ `Sigla Empresa`, data = df_p1)