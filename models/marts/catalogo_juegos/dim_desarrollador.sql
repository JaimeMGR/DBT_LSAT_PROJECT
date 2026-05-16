{{ config(materialized = 'table') }}

/*
  DIMENSIÓN: dim_desarrollador
  MART:      Catálogo de juegos
  ORIGEN:    int_games__developers

  Incluye total_juegos: número de juegos publicados por cada desarrollador.
*/

WITH developers AS (
    SELECT * FROM {{ ref('int_games__developers') }}
),

games AS (
    SELECT id_developer, game_id FROM {{ ref('int_games__games') }}
)

SELECT
    d.id_developer          AS id_desarrollador,
    d.nombre,
    COUNT(g.game_id)        AS total_juegos
FROM developers d
LEFT JOIN games g ON d.id_developer = g.id_developer
GROUP BY 1, 2
