{{ config(materialized = 'table') }}

/*
  DIMENSIÓN: dim_tecnologia
  MART:      Catálogo de juegos
  ORIGEN:    int_games__game_technologies + int_games__technology_types

  Una fila = una tecnología única (combinación tipo + nombre).
*/

WITH tech AS (
    SELECT DISTINCT
        technology_type_id,
        technology_name
    FROM {{ ref('int_games__game_technologies') }}
),

tipos AS (
    SELECT type_id, type_name FROM {{ ref('int_games__technology_types') }}
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['t.technology_type_id', 't.technology_name']) }} AS id_tecnologia,
    tp.type_name                                                AS tipo_tecnologia,
    t.technology_name                                           AS nombre
FROM tech t
LEFT JOIN tipos tp ON t.technology_type_id = tp.type_id
