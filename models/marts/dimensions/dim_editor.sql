{{
    config(
        materialized = 'table'
    )
}}

/*
  MODELO: dim_editor
  CAPA:   Marts / Dimensions (Gold)
*/

WITH pub_dev AS (
    SELECT * FROM {{ ref('int_games__publishers_developers_normalized') }}
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['publisher_principal']) }}  AS id_editor,
    publisher_principal                                               AS nombre
FROM pub_dev
WHERE publisher_principal IS NOT NULL
QUALIFY ROW_NUMBER() OVER (PARTITION BY publisher_principal ORDER BY 1) = 1
