{{ config(materialized = 'table') }}

/*
  DIMENSIÓN: dim_genero
  MART:      Catálogo de juegos
  ORIGEN:    int_games__genres
*/

SELECT
    {{ dbt_utils.generate_surrogate_key(['genre_id']) }}        AS id_genero,
    genre_id                                                    AS id_genero_steam,
    genre_name                                                  AS nombre
FROM {{ ref('int_games__genres') }}
