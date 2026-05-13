{{
    config(
        materialized = 'table'
    )
}}

/*
  MODELO: dim_genero
  CAPA:   Marts / Dimensions (Gold)
*/

WITH generos AS (
    SELECT * FROM {{ ref('int_games__genres_unpivoted') }}
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['id_genero_steam']) }}  AS id_genero,
    id_genero_steam,
    nombre_genero                                                AS nombre,
    -- Género primario: TRUE si al menos un juego lo tiene como primario
    MAX(es_primario)                                             AS es_primario
FROM generos
WHERE id_genero_steam IS NOT NULL
GROUP BY 1, 2, 3
