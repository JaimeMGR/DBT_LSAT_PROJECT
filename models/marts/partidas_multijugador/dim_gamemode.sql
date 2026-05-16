{{ config(materialized = 'table') }}

/*
  DIMENSIÓN: dim_gamemode
  MART:      Partidas multijugador
  ORIGEN:    int_match__gamemodes
*/

SELECT
    id_gamemode,
    nombre
FROM {{ ref('int_match__gamemodes') }}
