{{
    config(
        materialized = 'table'
    )
}}

/*
  MODELO: dim_fecha
  CAPA:   Marts / Dimensions (Gold)
  DESCRIPCIÓN: Dimensión de fecha generada a partir de todas las fechas
               relevantes del dataset (lanzamiento + pico histórico).
               Genera una fila por cada fecha única.
*/

WITH fechas_lanzamiento AS (
    SELECT fecha_lanzamiento AS fecha FROM {{ ref('stg_kaggle__games') }}
    WHERE fecha_lanzamiento IS NOT NULL
),

fechas_pico AS (
    SELECT fecha_pico_historico AS fecha FROM {{ ref('stg_kaggle__games') }}
    WHERE fecha_pico_historico IS NOT NULL
),

todas_fechas AS (
    SELECT fecha FROM fechas_lanzamiento
    UNION
    SELECT fecha FROM fechas_pico
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['fecha']) }}    AS id_fecha,
    fecha                                                AS fecha_completa,
    YEAR(fecha)                                          AS anio,
    QUARTER(fecha)                                       AS trimestre,
    MONTH(fecha)                                         AS mes,
    MONTHNAME(fecha)                                     AS nombre_mes,
    DAY(fecha)                                           AS dia,
    DAYOFWEEK(fecha)                                     AS dia_semana,
    DAYNAME(fecha)                                       AS nombre_dia,
    CASE WHEN DAYOFWEEK(fecha) IN (1, 7) THEN TRUE
         ELSE FALSE END                                  AS es_fin_de_semana
FROM todas_fechas
