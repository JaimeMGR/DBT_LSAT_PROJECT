{{ config(materialized = 'view') }}

/*
  MODELO: int_games__genres
  CAPA:   Intermediate (Silver)
  ERD:    genres

  Catálogo único de géneros con su ID nativo de Steam.
  Si hay typos en el nombre (datos sucios), se queda con el más frecuente.
*/

WITH unpivoted AS (
    SELECT * FROM {{ ref('int_games__genres_unpivoted') }}
    WHERE id_genero_steam IS NOT NULL
),

rankeados AS (
    SELECT
        id_genero_steam,
        nombre_genero,
        COUNT(*) AS frecuencia,
        ROW_NUMBER() OVER (
            PARTITION BY id_genero_steam
            ORDER BY COUNT(*) DESC
        ) AS rn
    FROM unpivoted
    GROUP BY 1, 2
)

SELECT
    id_genero_steam                                             AS genre_id,
    nombre_genero                                               AS genre_name
FROM rankeados
WHERE rn = 1
