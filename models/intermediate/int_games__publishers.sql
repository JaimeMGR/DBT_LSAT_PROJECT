{{ config(materialized = 'view') }}

/*
  MODELO: int_games__publishers
  CAPA:   Intermediate (Silver)
  ERD:    publishers

  Catálogo único de editores. Toma el primer publisher de la lista
  separada por comas y elimina duplicados.
*/

WITH stg AS (
    SELECT
        TRIM(SPLIT_PART(publisher, ',', 1)) AS publisher_name
    FROM {{ ref('stg_kaggle__games') }}
    WHERE publisher IS NOT NULL
      AND TRIM(SPLIT_PART(publisher, ',', 1)) != ''
)

SELECT DISTINCT
    {{ dbt_utils.generate_surrogate_key(['publisher_name']) }}  AS id_publisher,
    publisher_name                                              AS nombre
FROM stg
