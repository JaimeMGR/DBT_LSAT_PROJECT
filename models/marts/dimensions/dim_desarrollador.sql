{{
    config(
        materialized = 'table'
    )
}}

/*
  MODELO: dim_desarrollador
  CAPA:   Marts / Dimensions (Gold)
*/

WITH pub_dev AS (
    SELECT * FROM {{ ref('int_games__publishers_developers_normalized') }}
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['developer_principal']) }}  AS id_desarrollador,
    developer_principal                                               AS nombre,
    total_juegos_dev                                                  AS total_juegos
FROM pub_dev
WHERE developer_principal IS NOT NULL
QUALIFY ROW_NUMBER() OVER (PARTITION BY developer_principal ORDER BY 1) = 1
