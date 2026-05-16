{{ config(materialized = 'table') }}

/*
  DIMENSIÓN: dim_editor
  MART:      Catálogo de juegos
  ORIGEN:    int_games__publishers
*/

SELECT
    id_publisher    AS id_editor,
    nombre
FROM {{ ref('int_games__publishers') }}
