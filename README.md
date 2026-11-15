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


# Desarrollo


## Pregunta 1: Ocupación entre aerolíneas

### Datos utilizados

- **Fuente:** Aerocivil, datos abiertos (datos.gov.co), *Transporte Aéreo – Tráfico por Equipo (Colombia)*. Periodo: enero de 2020 a junio de 2026.
- **Población de análisis:** registros de vuelos regulares (`Tipo Vuelo` = R) con `Sillas Ofrecidas` > 0 y `Pasajeros A Bordo` no faltante (77.371 registros, data frame `df_occ_reg`).
- **Aerolíneas comparadas (41.995 registros):** las cinco con más pasajeros en vuelos regulares que operaron durante todo el periodo (registros en 2026 y al menos 60 meses con datos): Avianca (AVA), Aires (ARE), AeroRepública (RPB), Copa Airlines (CMP) y Easyfly (EFY).
- **Aerolínea excluida:** Fast Colombia (VVC) quedó entre las cinco con más pasajeros, pero sus datos terminan en febrero de 2023, por lo que no es comparable con las demás. [https://www.supersociedades.gov.co/noticias-supersociedades/-/asset_publisher/atwl/content/proceso-de-fast-colombia-s.a.s-viva-air-]
- **Variable de interés:** factor de ocupación = `Pasajeros A Bordo` / `Sillas Ofrecidas`.

### Técnicas utilizadas

- Tablas de frecuencia absoluta, relativa y acumulada (registros por aerolínea) y distribución de la ocupación por clases.
- Medidas de tendencia central (media, mediana, moda) y de dispersión (rango, varianza, desviación estándar, rango intercuartílico).
- Cuartiles y percentiles (P10, P90).
- Ocupación ponderada (total de pasajeros / total de sillas) además de la media por registro.
- Boxplots e histogramas (en densidad) por aerolínea.
- Detección de atípicos con la regla del rango intercuartílico (Q1 − 1,5·RIC y Q3 + 1,5·RIC).
- Prueba de Kruskal-Wallis y comparaciones por pares con Wilcoxon y corrección de Bonferroni, porque la ocupación es muy asimétrica.

Scripts: `R/comparacion_aerolineas.R`. Resultados: `tablas/` y `figuras/`.

### Hallazgos principales

| Aerolínea | Registros | Media | Mediana | Desv. est. | RIC | Ocupación ponderada |
|---|---|---|---|---|---|---|
| Copa | 2.652 | 0,826 | 0,852 | 0,113 | 0,131 | 0,849 |
| Avianca | 19.991 | 0,790 | 0,821 | 0,142 | 0,163 | 0,806 |
| Aires | 6.317 | 0,795 | 0,817 | 0,114 | 0,142 | 0,794 |
| AeroRepública | 4.548 | 0,786 | 0,810 | 0,123 | 0,162 | 0,825 |
| Easyfly | 8.487 | 0,694 | 0,703 | 0,115 | 0,142 | 0,716 |

1. **Easyfly se separa claramente del resto.** Su mediana (0,703) está entre 0,107 y 0,149 puntos por debajo de las demás, y la diferencia es significativa frente a cada una (p ajustado < 2e-16).
2. **Copa tiene la mayor ocupación mediana** (0,852), con una ventaja pequeña (0,031 a 0,042) pero significativa frente a las otras cuatro, y el 50 % central más concentrado (RIC = 0,131).
3. **Avianca, Aires y AeroRepública están prácticamente empatadas** (medianas entre 0,810 y 0,821). Solo la diferencia Avianca – AeroRepública es significativa (p ajustado = 1,1e-05), y es de solo 0,011. El orden entre ellas cambia según se use la media por registro o la ocupación ponderada.
4. **Avianca es la más dispersa** (desviación estándar 0,142; RIC 0,163).
5. **Asimetría a la izquierda:** en las cinco aerolíneas la media es menor que la mediana.
6. **Atípicos:** entre 2,2 % y 4,2 % de los registros de cada aerolínea. Casi todos son bajos (1.363 en total); solo Easyfly tiene atípicos altos (39). No se concentran únicamente en la pandemia: 2021 tiene 398 y 2025 tiene 287. El 34 % de los atípicos bajos corresponde a registros de 1 o 2 vuelos, frente al 10,5 % en los registros no atípicos. Se asocia con registros pequeños, pero no lo explica todo.
7. **Kruskal-Wallis:** se rechaza la igualdad de la ocupación entre aerolíneas (χ² = 5177,7; gl = 4; p < 2,2e-16).

Easyfly promedia 51,7 sillas por vuelo, frente a 153 a 183 en las otras cuatro aerolíneas, lo que indica que opera aeronaves mucho más pequeñas. Su menor ocupación está asociada con este tipo de operación, aunque los datos no permiten establecer que sea la causa.

### Limitaciones

- Solo se analizan vuelos regulares con sillas reportadas; el taxi aéreo (T) no reporta sillas y queda fuera.
- `Pasajeros A Bordo` cuenta solo pasajeros de pago, por lo que la ocupación es una aproximación y puede subestimar la ocupación física real.
- Faltan los meses de abril a agosto de 2020 en cuatro de las cinco aerolíneas (periodo de cierre por la pandemia); no se imputaron. Easyfly registra 15 registros en julio y agosto de 2020.
- Con más de 40.000 registros casi cualquier diferencia resulta significativa; por eso se interpretan también las diferencias de mediana.
- Easyfly opera aeronaves de unas 52 sillas por vuelo en promedio, frente a 153 a 183 en las demás, por lo que su ocupación no es directamente comparable con la de las otras aerolíneas.

## Pregunta 2: Pandemia y temporadas

### Datos utilizados

- **2a (caída y recuperación):** `df_pax` (216.579 registros), agregado por mes (78 meses, enero 2020 a junio 2026). Se analizan `Pasajeros A Bordo` y `Número de Vuelos`.
- **Línea base:** promedio mensual de enero-febrero de 2020 (3.876.541 pasajeros y 42.899 vuelos por mes).
- **2b (temporadas):** `df_temp`, años completos 2022-2025 (136.559 registros), agregado por mes (48 meses).

### Técnicas utilizadas

- Índice de recuperación = valor del mes / base × 100, para pasajeros y para vuelos.
- Mes mínimo, caída máxima, primer mes con índice ≥ 100 y primer mes con recuperación sostenida (3 meses seguidos con índice ≥ 100).
- Temporadas: dentro de cada año se calculan los percentiles 25 y 75 de los pasajeros mensuales; un mes es de temporada alta si supera el P75 y baja si queda bajo el P25. Se clasifica como alta o baja si cumple la condición en **al menos 3 de los 4 años**. Los percentiles se calculan por año (y no con los 48 meses juntos) para que el crecimiento del tráfico entre 2022 y 2025 no haga parecer "altos" a los meses de los últimos años.
- Índice estacional = pasajeros del mes / promedio mensual del año, promediado entre años.

Script: `R/temporal_correlacion.R`. Resultados: `tablas/p2_*.csv` y `figuras/p2_*.png`.

### Hallazgos principales

**Caída y recuperación (2a).**

| Variable | Mes mínimo | Valor mínimo | Caída máxima | Primer mes ≥ 100 | Recuperación sostenida |
|---|---|---|---|---|---|
| Pasajeros a bordo | abril 2020 | 11.778 | 99,7 % | diciembre 2021 | marzo 2022 |
| Número de vuelos | abril 2020 | 3.227 | 92,5 % | diciembre 2021 | marzo 2022 |

| Año | Meses | Pasajeros totales | Índice promedio pasajeros | Índice promedio vuelos |
|---|---|---|---|---|
| 2020 | 12 | 14.526.303 | 31,2 | 41,0 |
| 2021 | 12 | 32.639.166 | 70,2 | 75,6 |
| 2022 | 12 | 52.599.764 | 113,1 | 102,6 |
| 2023 | 12 | 53.509.278 | 115,0 | 97,8 |
| 2024 | 12 | 60.901.450 | 130,9 | 106,9 |
| 2025 | 12 | 62.198.920 | 133,7 | 109,5 |
| 2026 | 6 | 31.120.346 | 133,8 | 111,0 |



1. **La caída fue casi total y muy rápida:** de marzo a abril de 2020 los pasajeros pasaron de 55,8 % a 0,3 % de la base. Entre abril y agosto de 2020 el índice de pasajeros se mantuvo entre 0,3 % y 0,8 %.
2. **La recuperación fue gradual:** en 2020 el índice promedio fue 31,2 y en 2021, 70,2. El nivel base se superó por primera vez en diciembre de 2021, volvió a bajar en febrero de 2022 (90,0) y se mantuvo por encima de 100 desde marzo de 2022. Es decir, la recuperación tomó unos 23 meses desde el mínimo.
3. **Los pasajeros se recuperaron más que los vuelos.** En 2023 los pasajeros estaban 15 % sobre la base mientras que los vuelos estaban 2,2 % por debajo (97,8). Los pasajeros crecieron más que los vuelos, algo consistente con más pasajeros por vuelo, aunque estos datos no permiten establecer la causa.

**Temporadas (2b), años 2022-2025.**

| Mes | Años en temporada alta (de 4) | Años en temporada baja (de 4) | Índice estacional medio | Clasificación |
|---|---|---|---|---|
| Enero | 1 | 1 | 1,017 | Intermedia |
| Febrero | 0 | 4 | 0,866 | **Baja** |
| Marzo | 0 | 2 | 0,944 | Intermedia |
| Abril | 0 | 3 | 0,921 | **Baja** |
| Mayo | 0 | 2 | 0,941 | Intermedia |
| Junio | 0 | 0 | 0,994 | Intermedia |
| Julio | 4 | 0 | 1,081 | **Alta** |
| Agosto | 2 | 0 | 1,066 | Intermedia |
| Septiembre | 0 | 0 | 0,982 | Intermedia |
| Octubre | 0 | 0 | 1,024 | Intermedia |
| Noviembre | 1 | 0 | 1,038 | Intermedia |
| Diciembre | 4 | 0 | 1,127 | **Alta** |


4. **Temporada alta: julio y diciembre** (en los cuatro años). Diciembre es el mes más fuerte (12,7 % sobre el promedio mensual) y julio el segundo (8,1 %). Agosto es alto en dos de los cuatro años y su índice (1,066) es cercano al de julio.
5. **Temporada baja: febrero y abril.** Febrero está en temporada baja los cuatro años (13,4 % bajo el promedio); abril, en tres de cuatro.
6. Los meses de mayor demanda coinciden con las vacaciones de mitad y fin de año. Es una hipótesis razonable, pero los datos no permiten comprobar la causa.

### Limitaciones

- La línea base son solo dos meses de 2020, y febrero es estacionalmente bajo (índice 0,866 en los años normales). Por eso el índice mezcla recuperación y estacionalidad: los meses de temporada alta quedan por encima de 100 aunque el tráfico "normal" no hubiera crecido.
- `Pasajeros A Bordo` se cuenta por trayecto: un viaje con escala se cuenta más de una vez, y no incluye pasajeros no pagos.
- La estacionalidad se estima con solo cuatro años; la regla de 3 de 4 años y los umbrales P25/P75 son criterios del grupo, y con otros umbrales podrían cambiar los meses intermedios.

## Pregunta 3: Asociación entre oferta y uso

### Datos utilizados

`df_occ`: registros con `Sillas Ofrecidas` > 0 y `Pasajeros A Bordo` no faltante (86.706 registros). Se excluye el taxi aéreo (no reporta sillas). Los diagramas de dispersión omiten los registros con 0 en alguna variable (escala logarítmica); por ejemplo, 902 registros tienen 0 pasajeros.

### Técnicas utilizadas

- Correlación de Pearson (lineal) y de Spearman (monótona, robusta a valores extremos) entre `Sillas Ofrecidas`, `Número de Vuelos` y `Pasajeros A Bordo`.
- Pearson sobre log(1 + x), porque las tres variables son muy asimétricas, y sobre los totales mensuales.
- Regresión lineal simple de pasajeros sobre sillas.
- Correlación de Spearman entre la ocupación y el tamaño del registro (sillas, vuelos).
- Diagramas de dispersión con escala logarítmica.

Script: `R/temporal_correlacion.R`. Resultados: `tablas/p3_*.csv` y `figuras/p3_*.png`.

### Hallazgos principales

| Pares de variables | Pearson | Spearman | Pearson (log) | Pearson (totales mensuales) |
|---|---|---|---|---|
| Sillas – Pasajeros | 0,994 | 0,989 | 0,965 | 0,994 |
| Vuelos – Pasajeros | 0,963 | 0,908 | 0,877 | 0,988 |
| Sillas – Vuelos | 0,970 | 0,912 | 0,903 | 0,996 |


1. **La relación es muy fuerte** en las tres parejas y con los cuatro métodos. La más fuerte es sillas-pasajeros (Pearson 0,994).
2. **Regresión:** cada silla ofrecida adicional se asocia con 0,809 pasajeros adicionales (intercepto −33,4) y la oferta de sillas explica el 98,7 % de la variabilidad de los pasajeros por registro (R² = 0,987). La pendiente es cercana a la ocupación ponderada de las aerolíneas regulares (0,72 a 0,85 en la pregunta 1).
3. **Spearman y la escala log dan valores menores** (por ejemplo, vuelos-pasajeros baja de 0,963 a 0,908 y 0,877): la correlación de Pearson está empujada en parte por los registros muy grandes.
4. **Una parte de la correlación es mecánica.** Un registro agrupa varios vuelos (mediana de 14) y tanto las sillas como los pasajeros crecen con el tamaño del registro. Prueba de ello: la ocupación casi no depende del tamaño (Spearman 0,161 con sillas y 0,135 con vuelos). Saber cuántas sillas se ofrecen casi determina el número de pasajeros, pero no dice qué tan llenos van los aviones.
5. Con totales mensuales las correlaciones suben a 0,988-0,996: la oferta y la demanda se mueven juntas en el tiempo.

### Limitaciones

- Correlación no implica causalidad: las aerolíneas ofrecen más sillas donde esperan más demanda, así que el efecto va en ambas direcciones.
- Los registros son agregados (mes × empresa × trayecto × equipo), no vuelos individuales.
- `Pasajeros A Bordo` solo cuenta pasajeros de pago y se cuenta por trayecto.
- Se excluyen los registros sin sillas (60 % del total, incluido todo el taxi aéreo), por lo que las conclusiones aplican solo a vuelos con sillas reportadas.

## Ley de los Grandes Números

### Datos utilizados

`df_pax` (216.579 registros). Variable: `Pasajeros A Bordo` por registro. Población: todos los registros.

### Técnicas utilizadas

Se calculó la media poblacional con todos los datos y se extrajeron muestras aleatorias sin reemplazo (`set.seed(42)`) de tamaños n = 10, 50, 100, 500, 1.000, 5.000, 10.000, 50.000 y 100.000. Para cada n se registró una muestra y, para ver el error típico, el promedio de 200 muestras. También se graficó la media acumulada de 3 muestras aleatorias independientes.

Script: `R/temporal_correlacion.R`. Resultados: `tablas/lgn_tabla.csv` y `figuras/lgn_*.png`.

### Hallazgos principales

- **Media poblacional:** μ = 1.419,8 pasajeros por registro. **Desviación estándar:** σ = 5.034,3. **Mediana:** 9. El 21,2 % de los registros tiene 0 pasajeros y el máximo es 133.048.
- La distribución está muy sesgada a la derecha: la media es 158 veces la mediana, y σ es 3,5 veces μ.

| n | Media de una muestra | Error relativo de esa muestra (%) | Error relativo medio de 200 muestras (%) | Desv. est. de las 200 medias |
|---|---|---|---|---|
| 10 | 256 | 82,0 | 82,7 | 1.755 |
| 50 | 785 | 44,7 | 41,4 | 799 |
| 100 | 612 | 56,9 | 30,8 | 555 |
| 500 | 1.735 | 22,2 | 13,5 | 235 |
| 1.000 | 1.399 | 1,46 | 9,03 | 161 |
| 5.000 | 1.495 | 5,31 | 4,48 | 80,2 |
| 10.000 | 1.366 | 3,78 | 2,90 | 50,3 |
| 50.000 | 1.431 | 0,79 | 1,05 | 19,1 |
| 100.000 | 1.426 | 0,458 | 0,664 | 11,9 |


1. **Se cumple la ley:** la media muestral se acerca a μ a medida que crece n, y las tres trayectorias de la media acumulada se estabilizan alrededor de μ.
2. **La convergencia es lenta** porque la variable es muy asimétrica y con valores extremos: con n = 1.000 todavía hay un error típico cercano al 9 %. El error baja aproximadamente como σ/√n.
3. **Con una sola muestra por n el error no siempre baja** al aumentar n: con n = 50 el error fue 44,7 % y con n = 100 fue 56,9 %; con n = 1.000 fue solo 1,46 % por suerte, aunque el error típico era 9,03 %. Por eso se promedia sobre 200 muestras, donde el error sí disminuye de forma sostenida (de 82,7 % con n = 10 a 0,66 % con n = 100.000).
4. **La dispersión de las medias baja como σ/√n:** con n = 1.000 la desviación estándar de las medias fue 161 y σ/√1.000 = 159; con n = 100.000 fue 11,9, menor que σ/√100.000 = 15,9, porque esa muestra ya es una parte grande (46 %) de la población de 216.579 registros.

### Limitaciones

- Cada registro es un agregado mes × empresa × trayecto × equipo, así que "una observación" no es un pasajero ni un vuelo.
- Es la misma variable que usa la pregunta 4 y el Teorema del Límite Central, lo que permite compararlos.

## Pregunta 4:

## Pregunta 5:
