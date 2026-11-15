#Leer los datos(recuerden hacer pull primero):
library(tidyverse)   # si no lo tienen: install.packages("tidyverse")


#Verificar que tengan la base de datos
file.exists("data/aerocivil_trafico.csv")

#Cargar df
df <- read_csv("data/aerocivil_trafico.csv")

#Crear df's limpios para responder las preguntas
# Para análisis de pasajeros (excluye los 20 NA)
df_pax <- df |> filter(!is.na(`Pasajeros A Bordo`))

# Para análisis de ocupación (sillas > 0)
df_occ <- df_pax |>
  filter(`Sillas Ofrecidas` > 0) |>
  mutate(Ocupacion = `Pasajeros A Bordo` / `Sillas Ofrecidas`)

# Solo vuelos regulares
df_occ_reg <- df_occ |> filter(`Tipo Vuelo` == "R")

# Nacional vs internacional (excluye E)
df_occ_reg_ni <- df_occ_reg |> filter(Tráfico %in% c("N", "I")) 

# Temporadas: años completos
df_temp <- df_pax |> filter(Año %in% 2022:2025)

#Semilla para resultados
set.seed(42)



#--------

#Esto es la carga de la base de datos, si realizaron pull correctamente ya deberían tenerlo
#No es necesario que lo ejecuten, probablemente les salga error


lineas <- readLines("data/raw/datos.csv", encoding = "UTF-8")
lineas <- sub("^(\\d),(\\d{3}),", "\\1\\2,", lineas)
writeLines(lineas, "data/raw/datos_corregido.csv")

# Leer todo como texto y luego convertir las numéricas
df <- read_csv("data/raw/datos_corregido.csv",
               col_types = cols(.default = col_character()))

cols_num <- c("Año", "Mes", "Número de Vuelos", "Horas Bloque", "Sillas Ofrecidas",
              "Pasajeros A Bordo", "Pasajeros Tránsito", "Carga Ofrecida (Kg.)",
              "Carga + Correo A Bordo (Kg.)", "Carga Tránsito (Kg.)")

df <- df |>
  mutate(across(all_of(cols_num),
                ~ parse_number(.x, locale = locale(decimal_mark = ".", grouping_mark = ","))))

#Diagnosticos de carga
df |>
  filter(`Número de Vuelos` > 0) |>
  summarise(mediana_horas_por_vuelo = median(`Horas Bloque` / `Número de Vuelos`, na.rm = TRUE))

colSums(is.na(df))

dim(df)               # debe dar 216599 y 27
median(df$`Horas Bloque` / df$`Número de Vuelos`, na.rm = TRUE)   # debe dar cerca de 1.12

#Revisar filas duplicadas

sum(duplicated(df))
#Resultados esperados:
#[1] 0

df |> filter(duplicated(df) | duplicated(df, fromLast = TRUE)) |> head(20)

#Resultados esperados:
# A tibble: 0 × 27
# ℹ 27 variables: Año <dbl>, Mes <dbl>, Sigla Empresa <chr>, Nombre <chr>,
#   Origen <chr>, Nombre Origen <chr>, Ciudad Origen <chr>,
#   Departamento Origen <chr>, Pais Origen <chr>, Continente Origen <chr>,
#   Destino <chr>, Nombre Destino <chr>, Ciudad Destino <chr>,
#   Departamento Destino <chr>, Pais Destino <chr>, Continente Destino <chr>,
#   Tipo de Equipo <chr>, Tipo Vuelo <chr>, Tráfico <chr>, Número de Vuelos <dbl>,
#   Horas Bloque <dbl>, Sillas Ofrecidas <dbl>, Pasajeros A Bordo <dbl>, …
