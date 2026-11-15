#Limpieza de datos

#Verificar que se cargaron los datos correctamente
dim(df)               # filas y columnas: 216599     27
df |> count(Año)      # debe mostrar 2020 26713, 2021 36513, 2022 37909
                      #              2023 33982, 2024 31109, 2025 33567
                      #              2026 16806
glimpse(df)           # revisar que Horas Bloque, Pasajeros, etc. sean numéricas (dbl)

#Verificación de datos

# 1. Verificar si los NA de Departamento son aeropuertos del exterior
df |> filter(is.na(`Departamento Origen`)) |> count(`Pais Origen`, sort = TRUE) |> head(10)
df |> filter(is.na(`Departamento Destino`)) |> count(`Pais Destino`, sort = TRUE) |> head(10)

# 2. Los 20 NA en pasajeros
df |> filter(is.na(`Pasajeros A Bordo`)) |>
  select(Año, Mes, `Sigla Empresa`, `Tipo Vuelo`, Tráfico, `Número de Vuelos`, `Sillas Ofrecidas`)

# 3. Valores negativos (no deberían existir)
df |> summarise(across(where(is.numeric), ~ sum(.x < 0, na.rm = TRUE)))

# 4. Categorías de Tipo Vuelo y Tráfico
df |> count(`Tipo Vuelo`, sort = TRUE)
df |> count(Tráfico, sort = TRUE)

# 5. Meses presentes en 2026
df |> filter(Año == 2026) |> count(Mes)

# 6. Sillas en cero y ocupación mayor a 1
df |> summarise(sillas_cero = sum(`Sillas Ofrecidas` == 0),
                pct_sillas_cero = round(mean(`Sillas Ofrecidas` == 0) * 100, 1))

df_occ <- df |>
  filter(`Sillas Ofrecidas` > 0, !is.na(`Pasajeros A Bordo`)) |>
  mutate(Ocupacion = `Pasajeros A Bordo` / `Sillas Ofrecidas`)

nrow(df_occ)
sum(df_occ$Ocupacion > 1)
summary(df_occ$Ocupacion)

#Número de sillas con ocupación 0
df |> count(`Tipo Vuelo`, sillas_cero = `Sillas Ofrecidas` == 0)

#Sillas con ocupacion 1
sum(df_occ$Ocupacion == 1)
mean(df_occ$Ocupacion == 1) * 100

#Trafico nacional
df |> count(Tráfico, `Pais Origen` == "COLOMBIA", `Pais Destino` == "COLOMBIA")


#------

#Creación de datasets para trabajar acorde a los resultados de la verificación de datos

# Para análisis de pasajeros (excluye los 20 NA)
df_pax <- df |> filter(!is.na(`Pasajeros A Bordo`))

# Para análisis de ocupación sin sillas 0 (preguntas 1 y 5): sillas > 0
df_occ <- df_pax |>
  filter(`Sillas Ofrecidas` > 0) |>
  mutate(Ocupacion = `Pasajeros A Bordo` / `Sillas Ofrecidas`)

# Para análisis de temporadas: años completos
df_temp <- df_pax |> filter(Año %in% 2022:2025)

# Para pregunta 5: vuelos regulares, nacional vs internacional (excluye E)
df_occ_reg_ni <- df_occ_reg |> filter(Tráfico %in% c("N", "I"))
nrow(df_occ_reg_ni)

#Preguntas de ocupación regular
df_occ_reg <- df_occ |> filter(`Tipo Vuelo` == "R")


#------

#Verificar peso de T: Taxi Aereo en el analisis de pasajeros
#Debido a que su ocupacion se reporta como 0 en su totalidad, su ocupación es indefinida
df_pax |>
  group_by(`Tipo Vuelo`) |>
  summarise(registros = n(),
            pasajeros = sum(`Pasajeros A Bordo`),
            pct_pasajeros = round(100 * pasajeros / sum(df_pax$`Pasajeros A Bordo`), 2))

#Reporte de las dimensiones de los dataframes a usar
nrow(df); nrow(df_pax); nrow(df_occ); nrow(df_occ_ni); nrow(df_temp)
nrow(df); nrow(df_pax); nrow(df_occ); nrow(df_occ_ni); nrow(df_temp)
nrow(df_occ_reg)
