{{ config(materialized = 'table') }}

/*
  PUENTE: puente_juego_tecnologia
  MART:   Catálogo de juegos
  ORIGEN: int_games__game_technologies

  Resuelve la relación muchos a muchos entre dim_juego y dim_tecnologia.
*/

SELECT
    {{ dbt_utils.generate_surrogate_key(['game_id']) }}                              AS id_juego,
    {{ dbt_utils.generate_surrogate_key(['technology_type_id', 'technology_name']) }} AS id_tecnologia
FROM {{ ref('int_games__game_technologies') }}
