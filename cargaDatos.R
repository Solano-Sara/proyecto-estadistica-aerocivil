#Leer los datos(recuerden hacer pull primero):
library(tidyverse)   # si no lo tienen: install.packages("tidyverse")

df <- read_csv("data/aerocivil_trafico.csv")



#--------

#Esto es la carga de la base de datos, si realizaron pull correctamente ya deberían tenerlo

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
