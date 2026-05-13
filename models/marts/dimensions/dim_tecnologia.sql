{{
    config(
        materialized = 'table'
    )
}}

/*
  MODELO: dim_tecnologia
  CAPA:   Marts / Dimensions (Gold)
*/

WITH tecn AS (
    SELECT * FROM {{ ref('int_games__technologies_unpivoted') }}
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['tipo_tecnologia', 'nombre_tecnologia']) }}  AS id_tecnologia,
    tipo_tecnologia,
    nombre_tecnologia                                                                  AS nombre
FROM tecn
WHERE nombre_tecnologia IS NOT NULL
  AND tipo_tecnologia IS NOT NULL
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY tipo_tecnologia, nombre_tecnologia ORDER BY 1
) = 1
