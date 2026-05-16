{{ config(materialized = 'view') }}

/*
  MODELO: int_games__technology_types
  CAPA:   Intermediate (Silver)
  ERD:    technologie_types

  Catálogo de tipos de tecnología detectados (Engine, SDK, Anti-cheat, etc.).
*/

WITH unpivoted AS (
    SELECT DISTINCT tipo_tecnologia
    FROM {{ ref('int_games__technologies_unpivoted') }}
    WHERE tipo_tecnologia IS NOT NULL
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['tipo_tecnologia']) }} AS type_id,
    tipo_tecnologia                                             AS type_name
FROM unpivoted
