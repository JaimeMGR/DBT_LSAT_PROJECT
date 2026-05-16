{{ config(materialized = 'view') }}

/*
  MODELO: int_games__games
  CAPA:   Intermediate (Silver)
  ERD:    games

  Entidad principal del juego. Resuelve las claves foráneas a publishers
  y developers, y se queda solo con la información descriptiva del juego.
  Las métricas se separan en int_games__game_metrics.
*/

WITH stg AS (
    SELECT * FROM {{ ref('stg_kaggle__games') }}
),

publishers AS (
    SELECT id_publisher, nombre FROM {{ ref('int_games__publishers') }}
),

developers AS (
    SELECT id_developer, nombre FROM {{ ref('int_games__developers') }}
)

SELECT
    s.id_steam                                                  AS game_id,
    s.nombre_juego                                              AS game_name,
    s.link                                                      AS steam_app_link,
    s.fecha_lanzamiento                                         AS release_date,
    p.id_publisher,
    d.id_developer,
    s.genero_primario                                           AS primary_genre,
    s.fecha_mod_tienda                                          AS store_asset_mod_date
FROM stg s
LEFT JOIN publishers p
       ON TRIM(SPLIT_PART(s.publisher, ',', 1)) = p.nombre
LEFT JOIN developers d
       ON TRIM(SPLIT_PART(s.developer, ',', 1)) = d.nombre
WHERE s.id_steam IS NOT NULL
