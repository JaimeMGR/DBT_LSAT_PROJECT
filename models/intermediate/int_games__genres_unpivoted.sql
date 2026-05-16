{{
    config(
        materialized = 'view'
    )
}}

/*
  MODELO: int_games__genres_unpivoted
  CAPA:   Intermediate (Silver)
  ORIGEN: stg_kaggle__games

  Propósito:
    El campo store_genres contiene una lista de géneros separados por coma,
    por ejemplo: "Action (1), Indie (23), Adventure (25)"
    Este modelo la "explota" para obtener una fila por cada par juego-género,
    extrayendo también el ID de Steam de cada género.

  Ejemplo de salida:
    id_steam | nombre_genero | id_genero_steam | es_primario
    2231450  | Action        | 1               | TRUE
    2231450  | Indie         | 23              | FALSE
*/

WITH stg AS (

    SELECT
        id_steam,
        genero_primario,
        id_genero_primario_steam,
        store_genres
    FROM {{ ref('stg_kaggle__games') }}
    WHERE store_genres IS NOT NULL
      AND id_steam IS NOT NULL

),

-- Snowflake: SPLIT_TO_TABLE explota la lista de géneros en filas
generos_explotados AS (

    SELECT
        s.id_steam,
        s.genero_primario,
        s.id_genero_primario_steam,
        TRIM(g.VALUE::STRING)    AS genero_raw
    FROM stg s,
    LATERAL SPLIT_TO_TABLE(s.store_genres, ',') g

),

-- Limpia el nombre y extrae el ID de cada género de la lista
generos_parseados AS (

    SELECT
        id_steam,
        -- Nombre limpio: "Action (1)" → "Action"
        TRIM(REGEXP_REPLACE(genero_raw, '\\s*\\([0-9]+\\)', ''))         AS nombre_genero,

        -- ID Steam del género: "Action (1)" → 1
        TRY_TO_NUMBER(
            REGEXP_SUBSTR(genero_raw, '\\(([0-9]+)\\)', 1, 1, 'e', 1)
        )                                                                AS id_genero_steam,

        -- Flag: indica si es el género principal del juego
        CASE
            WHEN TRIM(REGEXP_REPLACE(genero_raw, '\\s*\\([0-9]+\\)', ''))
                 = genero_primario
            THEN TRUE
            ELSE FALSE
        END                                                              AS es_primario

    FROM generos_explotados
    WHERE TRIM(genero_raw) != ''

)

SELECT * FROM generos_parseados
