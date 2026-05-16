{{ config(materialized = 'view') }}

/*
  MODELO: int_match__gamemodes
  CAPA:   Intermediate (Silver)
  ERD:    gamemode

  Catálogo único de modos de juego ya normalizados en staging.
  El staging eliminó los typos como '@ren@ 3v3' o 'battle r0yale'.
*/

WITH stg AS (
    SELECT DISTINCT gamemode
    FROM {{ ref('stg_kaggle__match') }}
    WHERE gamemode IS NOT NULL
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['gamemode']) }}        AS id_gamemode,
    gamemode                                                    AS nombre
FROM stg
