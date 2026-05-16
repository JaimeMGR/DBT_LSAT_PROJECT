{% docs proyecto_steam_games %}
# Proyecto Steam Games — Pipeline de Datos

## Descripción general

Pipeline de datos completo para analizar el catálogo de **Steam**, la mayor plataforma
de distribución de videojuegos del mundo. El dataset cubre aproximadamente **67.500 juegos**
e incluye métricas de jugadores activos, reseñas de la comunidad, géneros,
tecnologías detectadas y datos de desarrolladores y editores.

El proyecto sigue una **arquitectura medallion** (Bronze → Silver → Gold) implementada
con **dbt Cloud** sobre **Snowflake**, y los datos finales se consumen desde **Power BI**.

## Objetivo

Proporcionar un modelo dimensional limpio y fiable que permita responder preguntas como:
- ¿Qué géneros generan mayor volumen de jugadores y reseñas?
- ¿Qué tecnologías usan los juegos más exitosos?
- ¿Cuánto tardan los juegos en alcanzar su pico de jugadores?
- ¿Qué desarrolladores tienen mejor ratio de retención de jugadores?

## Arquitectura

DEV
Change branch


Create a pull request on GitHub



Save
1415161718192021222324111213891067345

Commands
Code quality
Markdown Preview$0
DEV
Change branch


Create a pull request on GitHub



Save
1415161718192021222324111213891067345

Commands
Code quality
Markdown Preview$0
| Capa | Base de datos | Propósito |
|------|--------------|-----------|
| **Bronze** | `DEV_BRONZE_DB_STEAM` | Datos crudos tal cual llegan del CSV. Todo VARCHAR. |
| **Silver** | `DEV_SILVER_DB_STEAM` | Datos limpios, tipados y normalizados. |
| **Gold** | `DEV_GOLD_DB_STEAM` | Modelo dimensional listo para Power BI. |

{% enddocs %}


{% docs stg_kaggle__games %}
Modelo de staging que transforma la tabla raw `GAMES_RAW` de Bronze.
Aplica limpieza de strings, conversión de tipos, parseo de fechas en múltiples
formatos y extracción de IDs de Steam. Una fila = un juego único (deduplicado).
{% enddocs %}


{% docs fct_actividad_juego %}
Tabla de hechos central del modelo dimensional.
Contiene todas las métricas de actividad de cada juego:
jugadores simultáneos, reseñas, puntuación y métricas calculadas
como `dias_hasta_pico` y `ratio_retencion`.
Una fila = un juego con sus métricas en el momento de la carga.
{% enddocs %}


{% docs dim_juego %}
Dimensión de juego. Contiene los atributos descriptivos e invariables
de cada juego: nombre, link a Steam, fecha de modificación en tienda
y flag de si es un juego indie.
Una fila = un juego único identificado por su ID de Steam.
{% enddocs %}


{% docs dim_fecha %}
Dimensión de fecha construida a partir de todas las fechas únicas
del dataset (lanzamientos y picos históricos). Incluye atributos
de calendario: año, trimestre, mes, día y flag de fin de semana.
{% enddocs %}


{% docs dim_desarrollador %}
Dimensión de desarrollador. Contiene el nombre normalizado de cada
estudio o persona que ha desarrollado al menos un juego en el dataset,
junto con el total de juegos que tiene en Steam.
{% enddocs %}


{% docs dim_genero %}
Dimensión de género Steam. Cada fila es un género único con su ID
nativo de Steam y el flag que indica si algún juego lo tiene como género primario.
{% enddocs %}


{% docs dim_tecnologia %}
Dimensión de tecnología detectada en los juegos de Steam.
Incluye el tipo de tecnología (Engine, SDK, Anti-cheat, etc.)
y el nombre concreto (Unity, Unreal, FMOD, cURL, etc.).
{% enddocs %}


{% docs dim_segmento %}
Dimensión estática de segmentación de juegos por volumen de reseñas.
Permite clasificar cada juego en: Nicho, Pequeño, Medio, Grande o AAA.
{% enddocs %}


{% docs id_steam %}
Identificador numérico nativo del juego en la plataforma Steam.
Extraído del campo `link` mediante expresión regular: `/app/(\d+)/`.
{% enddocs %}


{% docs ratio_retencion %}
Métrica calculada: proporción de jugadores actuales respecto al pico histórico.
Un valor cercano a 1 indica que el juego mantiene prácticamente todos sus jugadores.
Un valor cercano a 0 indica que el juego ha perdido casi toda su base de jugadores.
Fórmula: `jugadores_actuales / pico_historico`.
{% enddocs %}


{% docs dias_hasta_pico %}
Métrica calculada: número de días transcurridos desde la fecha de lanzamiento
hasta que el juego alcanzó su máximo histórico de jugadores simultáneos.
Un valor bajo indica que el juego tuvo un lanzamiento explosivo.
Un valor alto puede indicar crecimiento orgánico o un pico tardío por descuentos.
{% enddocs %}


{% docs flag_fecha_invalida %}
Flag de calidad de datos (TRUE/FALSE). Indica que el campo `release` en la
tabla raw existía pero ninguno de los formatos de fecha soportados pudo parsearlo.
Estos registros tienen `fecha_lanzamiento = NULL` en Silver.
{% enddocs %}


{% docs flag_numero_invalido %}
Flag de calidad de datos (TRUE/FALSE). Indica que algún campo numérico clave
(`peak_players` o `rating`) vino con un valor no convertible (texto, N/A, etc.).
{% enddocs %}
