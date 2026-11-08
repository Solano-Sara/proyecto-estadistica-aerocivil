# proyecto-estadistica-aerocivil

Para trabajar con el data set utilizar

library(tidyverse)

df <- read_csv("data/aerocivil_trafico.csv")

----------
Detalles de las variables a tener en cuenta para el analisis y trabajo.

Pasajeros A Bordo: 20 NA. (recomendado excluirlos solo en los análisis de pasajeros)

Carga + Correo A Bordo: 752 NA.

Departamento Origen/Destino: 17.818 y 16.290 NA. (Todos son países extranjeros (EE. UU., Panamá, Brasil...))

Año: 2026 datos de enero a junio (Excluir de analisis de temporada por mes)

