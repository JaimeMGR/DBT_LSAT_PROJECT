{{ config(materialized = 'table') }}

/*
  DIMENSIÓN: dim_region
  MART:      Partidas multijugador
  ORIGEN:    int_match__regions
*/

SELECT
    id_region,
    nombre
FROM {{ ref('int_match__regions') }}
