{{
    config(
        materialized = 'table'
    )
}}

/*
  MODELO: fct_actividad_juego
  CAPA:   Marts / Facts (Gold)
  DESCRIPCIÓN: Tabla de hechos central del modelo dimensional.
               Una fila = un juego con todas sus métricas de actividad.

  Métricas calculadas:
    - dias_hasta_pico: días desde lanzamiento hasta el pico histórico
    - ratio_retencion: jugadores_actuales / pico_historico
*/

WITH stg AS (
    SELECT * FROM {{ ref('stg_kaggle__games') }}
),

pub_dev AS (
    SELECT * FROM {{ ref('int_games__publishers_developers_normalized') }}
),

dim_juego AS (
    SELECT * FROM {{ ref('dim_juego') }}
),

dim_fecha_lanz AS (
    SELECT * FROM {{ ref('dim_fecha') }}
),

dim_fecha_pico AS (
    SELECT * FROM {{ ref('dim_fecha') }}
),

dim_desarrollador AS (
    SELECT * FROM {{ ref('dim_desarrollador') }}
),

dim_editor AS (
    SELECT * FROM {{ ref('dim_editor') }}
),

dim_segmento AS (
    SELECT * FROM {{ ref('dim_segmento') }}
)

SELECT

    -- ── CLAVES FORÁNEAS ──────────────────────────────────────────────────────
    dj.id_juego,
    df_lanz.id_fecha                                            AS id_fecha_lanzamiento,
    df_pico.id_fecha                                            AS id_fecha_pico,
    dd.id_desarrollador,
    de.id_editor,
    ds.id_segmento,

    -- ── MÉTRICAS DE JUGADORES ────────────────────────────────────────────────
    stg.pico_jugadores_reciente,
    stg.jugadores_actuales,
    stg.pico_24h,
    stg.pico_historico,

    -- ── MÉTRICAS DE RESEÑAS ──────────────────────────────────────────────────
    stg.resenas_positivas,
    stg.resenas_negativas,
    stg.total_resenas,
    stg.puntuacion,
    stg.porcentaje_positivo,

    -- ── MÉTRICAS CALCULADAS ──────────────────────────────────────────────────
    -- Días desde lanzamiento hasta el pico histórico
    DATEDIFF('day', stg.fecha_lanzamiento, stg.fecha_pico_historico)
                                                                AS dias_hasta_pico,

    -- Ratio de retención: jugadores actuales vs pico histórico (0-1)
    CASE
        WHEN stg.pico_historico > 0
        THEN ROUND(stg.jugadores_actuales / stg.pico_historico::FLOAT, 4)
        ELSE NULL
    END                                                         AS ratio_retencion,

    -- ── FLAGS DE CALIDAD (heredados de staging) ──────────────────────────────
    stg.flag_fecha_invalida,
    stg.flag_numero_invalido

FROM stg

-- Joins a dimensiones
INNER JOIN dim_juego dj
        ON stg.id_steam = dj.id_steam

LEFT JOIN dim_fecha df_lanz
       ON stg.fecha_lanzamiento = df_lanz.fecha_completa

LEFT JOIN dim_fecha df_pico
       ON stg.fecha_pico_historico = df_pico.fecha_completa

LEFT JOIN pub_dev pd
       ON stg.id_steam = pd.id_steam

LEFT JOIN dim_desarrollador dd
       ON pd.developer_principal = dd.nombre

LEFT JOIN dim_editor de
       ON pd.publisher_principal = de.nombre

-- Asignación de segmento según total de reseñas
LEFT JOIN dim_segmento ds
       ON stg.total_resenas BETWEEN
            CASE ds.id_segmento
                WHEN 1 THEN 0
                WHEN 2 THEN 101
                WHEN 3 THEN 1001
                WHEN 4 THEN 10001
                WHEN 5 THEN 100001
            END
          AND
            CASE ds.id_segmento
                WHEN 1 THEN 100
                WHEN 2 THEN 1000
                WHEN 3 THEN 10000
                WHEN 4 THEN 100000
                WHEN 5 THEN 999999999
            END

WHERE stg.id_steam IS NOT NULL
