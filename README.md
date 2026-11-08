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
## Data frames de trabajo

Todos parten de `data/aerocivil_trafico.csv` (216.599 filas, 27 columnas). Los filtros se aplican en el script `limpiezaDatos.R`; el archivo base no se modifica.

| Data frame | Filtro | Filas | Se usa en |
|---|---|---|---|
| `df` | Ninguno (todos los registros) | 216.599 | Datos completos |
| `df_pax` | Excluye los 20 registros sin `Pasajeros A Bordo` | 216.579 | Preguntas 2 y 4, LGN y TLC |
| `df_occ` | `df_pax` con `Sillas Ofrecidas` > 0; agrega `Ocupacion` = pasajeros / sillas | 86.706 | Pregunta 3 |
| `df_occ_reg` | `df_occ` solo con `Tipo Vuelo` = R (regular) | 77.371 | Pregunta 1 y base de la pregunta 5 |
| `df_occ_reg_ni` | `df_occ` con `Tráfico` = N o I (excluye E) y `Tipo Vuelo` = R (regular)| 86.565 | Pregunta 5 (todos los tipos de vuelo) |
| `df_temp` | `df_pax` de 2022 a 2025 (años completos) | 136.559 | Pregunta 2b (temporadas) |

**Notas:**
- El taxi aéreo (T) no reporta sillas, por eso queda fuera de `df_occ` y sus derivados.
- 2026 solo llega hasta junio, por eso no se usa en `df_temp`.
- Si la pregunta 5 se limita a vuelos regulares, usar `df_occ_reg |> filter(Tráfico %in% c("N", "I"))`.

```r
# Para análisis de pasajeros (excluye los 20 NA)
df_pax <- df |> filter(!is.na(`Pasajeros A Bordo`))

# Para análisis de ocupación (sillas > 0)
df_occ <- df_pax |>
  filter(`Sillas Ofrecidas` > 0) |>
  mutate(Ocupacion = `Pasajeros A Bordo` / `Sillas Ofrecidas`)

# Para análisis de temporadas: años completos
df_temp <- df_pax |> filter(Año %in% 2022:2025)

# Para pregunta 5: nacional vs internacional (excluye E)
df_occ_ni <- df_occ |> filter(Tráfico %in% c("N", "I"))

# Para preguntas de ocupación: solo vuelos regulares
df_occ_reg <- df_occ |> filter(`Tipo Vuelo` == "R")
```

----------
## Preguntas de investigación

### Pregunta 1: Diferencias de ocupación entre aerolíneas
**¿Cómo difiere el factor de ocupación (`Pasajeros A Bordo` / `Sillas Ofrecidas`) entre las cinco aerolíneas(número propuesto, cambiar acorde a número de pasajeros por aerolinea) con más pasajeros que operan vuelos regulares?**

- **Qué se pretende conocer:** si existen diferencias sistemáticas en el aprovechamiento de las sillas entre empresas (`Sigla Empresa`), comparando media, mediana, dispersión y boxplots de la ocupación por aerolínea.
- **Razón de interes:** la ocupación indica qué tan eficientemente cada empresa usa su capacidad, lo que se relaciona con su rentabilidad y su estrategia comercial.
- **Datos usados:** registros de tipo de vuelo regular (R) con `Sillas Ofrecidas` > 0 (77.371 registros).

### Pregunta 2: Pandemia y temporadas
**2a. ¿Cómo cayó y cómo se recuperó el tráfico de pasajeros durante y después de la pandemia (2020–2022)?**
**2b. ¿Qué meses son temporada alta y cuáles temporada baja en los años completos posteriores (2022–2025)?**

- **Qué se pretende conocer:** (a) la magnitud de la caída y el tiempo de recuperación de `Pasajeros A Bordo` y `Número de Vuelos` respecto al promedio de enero–febrero de 2020, mediante un índice de recuperación; (b) la estacionalidad mensual, definiendo temporada alta como los meses con pasajeros por encima del percentil 75 y temporada baja como los meses por debajo del percentil 25.
- **Razón de interes:** cuantifica el impacto de un evento extremo en el transporte aéreo e identifica los meses de mayor y menor demanda, útil para planear la capacidad.
- **Limitación:** el conjunto de datos empieza en enero de 2020, por lo que no hay un periodo prepandemia completo; la línea base son solo dos meses. 2026 llega hasta junio y no se usa en la estacionalidad.

### Pregunta 3: Asociación entre oferta y uso
**¿Qué tan fuerte es la relación entre las sillas ofrecidas, el número de vuelos y los pasajeros transportados?**

- **Qué se pretende conocer:** el grado de asociación entre `Sillas Ofrecidas`, `Número de Vuelos` y `Pasajeros A Bordo`, mediante diagramas de dispersión y coeficientes de correlación de Pearson y Spearman.
- **Razón de interes:** permite saber si una mayor oferta de sillas o de vuelos se refleja en más pasajeros, o si la demanda se comporta de forma independiente de la oferta.
- **Datos usados:** registros con `Sillas Ofrecidas` > 0 (se excluye el taxi aéreo, que no reporta sillas).

### Pregunta 4: Distribución y concentración del tráfico
**¿Cómo se distribuyen los pasajeros por registro y qué porcentaje del total de pasajeros mueven los 10 principales aeropuertos de origen?**

- **Qué se pretende conocer:** la forma de la distribución de `Pasajeros A Bordo` (asimetría, valores extremos, ceros) y el porcentaje acumulado de pasajeros de los 10 principales aeropuertos de origen (`Nombre Origen`).
- **Razón de interes:** una distribución muy asimétrica y un tráfico concentrado indican que el sistema depende de pocos nodos, lo que tiene implicaciones para la infraestructura y para interpretar promedios. Además, prepara el análisis del Teorema del Límite Central.
- **Nota:** el taxi aéreo (T) es el 51 % de los registros pero solo el 0,57 % de los pasajeros, por lo que la distribución se muestra con todos los registros y también solo para vuelos regulares.

### Pregunta 5: Probabilidad condicional de ocupación alta
**¿Cambia la probabilidad de que un registro regular tenga ocupación alta (superior al 80 %) según sea tráfico nacional o internacional?**
(Pregunta para vuelos regulares, 

- **Qué se pretende conocer:** P(ocupación alta), P(ocupación alta | nacional) y P(ocupación alta | internacional), y si el evento es independiente del tipo de tráfico. Con el Teorema de Bayes se calcula la probabilidad inversa, P(internacional | ocupación alta).
- **Razón de interes:** muestra si conocer el tipo de tráfico aporta información sobre qué tan llenos van los aviones, y conecta con las secciones de probabilidad y Bayes.
- **Definiciones:** nacional (`Tráfico` = N) es origen y destino en Colombia; internacional (`Tráfico` = I) es exactamente un extremo en Colombia. Se excluye `Tráfico` = E (ningún extremo en Colombia, 0,6 % de los registros). El umbral de 80 % es una convención; la mediana de ocupación es 0,79 y el percentil 75 es 0,88.
