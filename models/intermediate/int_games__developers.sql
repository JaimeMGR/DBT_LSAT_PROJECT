{{ config(materialized = 'view') }}

/*
  MODELO: int_games__developers
  CAPA:   Intermediate (Silver)
  ERD:    developers

  Catálogo único de desarrolladores.
*/

WITH stg AS (
    SELECT
        TRIM(SPLIT_PART(developer, ',', 1)) AS developer_name
    FROM {{ ref('stg_kaggle__games') }}
    WHERE developer IS NOT NULL
      AND TRIM(SPLIT_PART(developer, ',', 1)) != ''
)

SELECT DISTINCT
    {{ dbt_utils.generate_surrogate_key(['developer_name']) }}  AS id_developer,
    developer_name                                              AS nombre
FROM stg
