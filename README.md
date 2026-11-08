# proyecto-estadistica-aerocivil

Para trabajar con el data set utilizar

library(tidyverse)

df <- read_csv("data/aerocivil_trafico.csv")

----------
## Diccionario de variables

Fuente: Aerocivil, datos abiertos (datos.gov.co), *Transporte Aéreo – Tráfico por Equipo (Colombia)*. Cada fila es una combinación empresa – trayecto origen-destino – tipo de equipo – mes. Periodo: enero 2020 a junio 2026. Dimensión: 216.599 filas y 27 columnas.

| # | Variable | Significado | Tipo | Unidad |
|---|---|---|---|---|
| 1 | Año | Año de la operación | Cuantitativa discreta | año |
| 2 | Mes | Mes de la operación (1 a 12) | Cualitativa ordinal | mes |
| 3 | Sigla Empresa | Sigla OACI de la empresa aérea | Cualitativa nominal | — |
| 4 | Nombre | Nombre de la empresa aérea | Cualitativa nominal | — |
| 5 | Origen | Código IATA del aeropuerto de origen | Cualitativa nominal | — |
| 6 | Nombre Origen | Nombre del aeropuerto de origen | Cualitativa nominal | — |
| 7 | Ciudad Origen | Ciudad del aeropuerto de origen | Cualitativa nominal | — |
| 8 | Departamento Origen | Departamento del aeropuerto de origen (NA si es del exterior) | Cualitativa nominal | — |
| 9 | Pais Origen | País del aeropuerto de origen | Cualitativa nominal | — |
| 10 | Continente Origen | Continente del país de origen | Cualitativa nominal | — |
| 11 | Destino | Código IATA del aeropuerto de destino | Cualitativa nominal | — |
| 12 | Nombre Destino | Nombre del aeropuerto de destino | Cualitativa nominal | — |
| 13 | Ciudad Destino | Ciudad del aeropuerto de destino | Cualitativa nominal | — |
| 14 | Departamento Destino | Departamento del aeropuerto de destino (NA si es del exterior) | Cualitativa nominal | — |
| 15 | Pais Destino | País del aeropuerto de destino | Cualitativa nominal | — |
| 16 | Continente Destino | Continente del país de destino | Cualitativa nominal | — |
| 17 | Tipo de Equipo | Código del tipo de aeronave según el Documento 8643 de la OACI (ej. C207, B788, A320) | Cualitativa nominal | — |
| 18 | Tipo Vuelo | Tipo de operación: A = adicional, C = chárter, N = no regular, R = regular, T = taxi aéreo (en los datos solo aparecen A, C, R y T) | Cualitativa nominal | — |
| 19 | Tráfico | N: origen y destino en Colombia. I: exactamente un extremo en Colombia. E: ningún extremo en Colombia (verificado con los datos) | Cualitativa nominal | — |
| 20 | Número de Vuelos | Contador de vuelos realizados para ese origen y destino en el registro | Cuantitativa discreta | vuelos |
| 21 | Horas Bloque | Tiempo entre calzos del vuelo | Cuantitativa continua | horas |
| 22 | Sillas Ofrecidas | Número total de asientos de pasajeros disponibles para la venta en los vuelos realizados | Cuantitativa discreta | sillas |
| 23 | Pasajeros A Bordo | Número de pasajeros de pago transportados en el trayecto (excluye quienes viajan gratis, tarifas de empleados y niños sin silla) | Cuantitativa discreta | pasajeros |
| 24 | Pasajeros Tránsito | Pasajeros que continúan su viaje desde la etapa precedente en la misma aeronave o con el mismo número de vuelo (no sumar a Pasajeros A Bordo) | Cuantitativa discreta | pasajeros |
| 25 | Carga Ofrecida (Kg.) | Capacidad de carga y correo disponible | Cuantitativa continua | kg |
| 26 | Carga + Correo A Bordo (Kg.) | Carga y correo transportados en el trayecto | Cuantitativa continua | kg |
| 27 | Carga Tránsito (Kg.) | Carga que continúa su viaje desde la etapa anterior | Cuantitativa continua | kg |


## Datos faltantes (NA)

| Variable | NA | Tratamiento |
|---|---|---|
| Departamento Origen | 17.818 | Aeropuertos del exterior; no se imputan |
| Departamento Destino | 16.290 | Aeropuertos del exterior; no se imputan |
| Pasajeros A Bordo | 20 | Se excluyen de los análisis de pasajeros |
| Carga + Correo A Bordo | 752 | No se usa en las preguntas de investigación |

No se encontraron duplicados ni valores negativos. El 60 % de los registros (129.892) tiene Sillas Ofrecidas = 0 (todos los de tipo T), por lo que la ocupación se calcula solo sobre 86.706 registros.
----------
Detalles de las variables a tener en cuenta para el analisis y trabajo.

Pasajeros A Bordo: 20 NA. (recomendado excluirlos solo en los análisis de pasajeros). Utilizar df_pax

Carga + Correo A Bordo: 752 NA.

Departamento Origen/Destino: 17.818 y 16.290 NA. (Todos son países extranjeros (EE. UU., Panamá, Brasil...)). Para pregunta 5: nacional vs internacional usar df_occ_ni

Año: 2026 datos de enero a junio (Excluir de analisis de temporada por mes). Para análisis de temporadas usar df_temp

