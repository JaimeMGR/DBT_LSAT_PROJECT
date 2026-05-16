{{ config(materialized = 'table') }}

/*
  PUENTE: puente_juego_genero
  MART:   Catálogo de juegos
  ORIGEN: int_games__game_genres

  Resuelve la relación muchos a muchos entre dim_juego y dim_genero.
  Las claves surrogadas se calculan igual que en las dimensiones para
  garantizar que los JOIN funcionen.
*/

SELECT
    {{ dbt_utils.generate_surrogate_key(['game_id']) }}         AS id_juego,
    {{ dbt_utils.generate_surrogate_key(['genre_id']) }}        AS id_genero,
    is_primary                                                  AS es_primario
FROM {{ ref('int_games__game_genres') }}
