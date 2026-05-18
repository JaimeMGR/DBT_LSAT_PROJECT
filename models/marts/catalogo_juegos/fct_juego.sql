{{
    config(
        materialized     = 'incremental',
        unique_key       = 'id_juego',
        on_schema_change = 'sync_all_columns'
    )
}}

/*
  HECHOS: fct_juego
  MART:   Catálogo de juegos
  ORIGEN: int_games__game_metrics + int_games__games + stg_kaggle__games

  Una fila = un juego con todas sus métricas de actividad.
  Materialización incremental: en cada ejecución solo procesa los juegos
  cuyo _loaded_at sea más reciente que el máximo ya cargado.

  Métricas calculadas:
    - dias_hasta_pico: días desde el lanzamiento hasta el pico histórico
    - ratio_retencion: jugadores actuales / pico histórico
*/

WITH games AS (
    SELECT * FROM {{ ref('int_games__games') }}
),

metrics AS (
    SELECT * FROM {{ ref('int_games__game_metrics') }}
),

-- Traemos _loaded_at desde staging para el filtro incremental
stg AS (
    SELECT id_steam, _loaded_at
    FROM {{ ref('stg_kaggle__games') }}

    {% if is_incremental() %}
        WHERE _loaded_at > (SELECT MAX(_loaded_at) FROM {{ this }})
    {% endif %}
)

SELECT
    -- ── CLAVES FORÁNEAS ──────────────────────────────────────────────────────
    {{ dbt_utils.generate_surrogate_key(['g.game_id']) }}           AS id_juego,
    g.id_publisher                                                  AS id_editor,
    g.id_developer                                                  AS id_desarrollador,
    {{ dbt_utils.generate_surrogate_key(['g.release_date']) }}      AS id_fecha_lanzamiento,
    {{ dbt_utils.generate_surrogate_key(['m.all_time_peak_date']) }} AS id_fecha_pico,

    -- Segmento según volumen de reseñas (1=Nicho ... 5=AAA)
    CASE
        WHEN m.total_reviews IS NULL    THEN NULL
        WHEN m.total_reviews <= 100     THEN 1
        WHEN m.total_reviews <= 1000    THEN 2
        WHEN m.total_reviews <= 10000   THEN 3
        WHEN m.total_reviews <= 100000  THEN 4
        ELSE 5
    END                                                             AS id_segmento,

    -- ── MÉTRICAS DE JUGADORES ────────────────────────────────────────────────
    m.peak_players                                                  AS pico_jugadores_reciente,
    m.players_right_now                                             AS jugadores_actuales,
    m.peak_players_24h                                              AS pico_24h,
    m.all_time_peak                                                 AS pico_historico,

    -- ── MÉTRICAS DE RESEÑAS ──────────────────────────────────────────────────
    m.positive_reviews                                              AS resenas_positivas,
    m.negative_reviews                                              AS resenas_negativas,
    m.total_reviews                                                 AS total_resenas,
    m.rating                                                        AS puntuacion,
    m.review_percentage                                             AS porcentaje_positivo,

    -- ── MÉTRICAS CALCULADAS ──────────────────────────────────────────────────
    DATEDIFF('day', g.release_date, m.all_time_peak_date)           AS dias_hasta_pico,
    CASE
        WHEN m.all_time_peak > 0
        THEN ROUND(m.players_right_now / m.all_time_peak::FLOAT, 4)
        ELSE NULL
    END                                                             AS ratio_retencion,

    -- ── AUDITORÍA ────────────────────────────────────────────────────────────
    s._loaded_at

FROM stg s
JOIN games   g ON s.id_steam = g.game_id
LEFT JOIN metrics m ON g.game_id = m.game_id
WHERE m.total_reviews IS NOT NULL
   OR m.all_time_peak IS NOT NULL;