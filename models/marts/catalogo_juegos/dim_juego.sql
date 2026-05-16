{{ config(materialized = 'table') }}

/*
  DIMENSIÓN: dim_juego
  MART:      Catálogo de juegos
  ORIGEN:    int_games__games

  Una fila = un juego único. La clave surrogada id_juego se calcula
  como hash del id_steam para mantener consistencia con las tablas puente.
*/

WITH games AS (
    SELECT * FROM {{ ref('int_games__games') }}
),

-- Un juego es indie si tiene el género 'Indie' entre sus géneros
indie_flag AS (
    SELECT DISTINCT gg.game_id
    FROM {{ ref('int_games__game_genres') }} gg
    JOIN {{ ref('int_games__genres') }} g ON gg.genre_id = g.genre_id
    WHERE UPPER(g.genre_name) = 'INDIE'
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['g.game_id']) }}       AS id_juego,
    g.game_id                                                   AS id_steam,
    g.game_name                                                 AS nombre,
    g.steam_app_link                                            AS enlace,
    g.primary_genre                                             AS genero_primario,
    g.store_asset_mod_date                                      AS fecha_mod_tienda,
    CASE WHEN i.game_id IS NOT NULL THEN TRUE ELSE FALSE END     AS es_indie
FROM games g
LEFT JOIN indie_flag i ON g.game_id = i.game_id
