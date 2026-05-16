{{ config(materialized = 'view') }}

/*
  MODELO: int_match__regions
  CAPA:   Intermediate (Silver)
  ERD:    region

  Catálogo único de regiones del servidor (NA, EUW, EUNE, SA, ASIA, OCE).
  Staging ya normalizó las mayúsculas/minúsculas inconsistentes.
*/

WITH stg AS (
    SELECT DISTINCT region
    FROM {{ ref('stg_kaggle__match') }}
    WHERE region IS NOT NULL
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['region']) }}          AS id_region,
    region                                                      AS nombre
FROM stg
