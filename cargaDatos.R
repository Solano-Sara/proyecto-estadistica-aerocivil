#Leer los datos:
library(tidyverse)   # si no lo tienen: install.packages("tidyverse")

df <- read_csv("data/aerocivil_trafico.csv")

#--------

#Esto es la carga de la base de datos, si realizaron pull correctamente ya deberían tenerlo
#Instalar los packages readxl y readr
library(readxl)
library(readr)


# Leer Excel
datos <- read_excel("Transporte_Aéreo_–_Tráfico_por_Equipo_(Colombia)_20261108.xlsx")

# Crear la carpeta data
dir.create("data", showWarnings = FALSE)

# Guardar como CSV
write_csv(datos, "data/aerocivil_trafico.csv")

