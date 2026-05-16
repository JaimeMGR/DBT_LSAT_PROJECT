{{ config(materialized = 'view') }}

/*
  MODELO: int_games__game_metrics
  CAPA:   Intermediate (Silver)
  ERD:    game_metrics

  Separa las métricas (jugadores + reseñas) del resto de información del juego.
  Una fila = un juego con sus métricas actuales.
*/

WITH stg AS (
    SELECT * FROM {{ ref('stg_kaggle__games') }}
    WHERE id_steam IS NOT NULL
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['id_steam']) }}        AS metric_id,
    id_steam                                                    AS game_id,
    pico_jugadores_reciente                                     AS peak_players,
    jugadores_actuales                                          AS players_right_now,
    pico_24h                                                    AS peak_players_24h,
    pico_historico                                              AS all_time_peak,
    fecha_pico_historico                                        AS all_time_peak_date,
    resenas_positivas                                           AS positive_reviews,
    resenas_negativas                                           AS negative_reviews,
    total_resenas                                               AS total_reviews,
    puntuacion                                                  AS rating,
    porcentaje_positivo                                         AS review_percentage
FROM stg
