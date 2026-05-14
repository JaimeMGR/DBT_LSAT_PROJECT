{{
    config(
        materialized = 'table'
    )
}}

/*
  MODELO: dim_genero
  CAPA:   Marts / Dimensions (Gold)

  Nota: agrupamos por id_genero_steam y tomamos el nombre más frecuente
  para evitar duplicados causados por typos en los datos de origen.
*/

WITH generos AS (
    SELECT * FROM {{ ref('int_games__genres_unpivoted') }}
    WHERE id_genero_steam IS NOT NULL
),

-- Contamos cuántas veces aparece cada combinación id+nombre
-- para quedarnos con el nombre canónico (el más frecuente)
generos_rankeados AS (
    SELECT
        id_genero_steam,
        nombre_genero,
        MAX(es_primario)                            AS es_primario,
        COUNT(*)                                    AS frecuencia,
        ROW_NUMBER() OVER (
            PARTITION BY id_genero_steam
            ORDER BY COUNT(*) DESC                  -- nombre más frecuente primero
        )                                           AS rn
    FROM generos
    GROUP BY 1, 2
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['id_genero_steam']) }}  AS id_genero,
    id_genero_steam,
    nombre_genero                                                AS nombre,
    es_primario
FROM generos_rankeados
WHERE rn = 1   -- solo el nombre más frecuente por cada ID de género
