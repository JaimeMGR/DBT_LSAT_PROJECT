{{
    config(
        materialized = 'table'
    )
}}

/*
  MODELO: puente_juego_genero
  CAPA:   Marts / Gold
  DESCRIPCIÓN: Tabla puente que resuelve la relación muchos a muchos
               entre DIM_JUEGO y DIM_GENERO.
               Una fila = un juego perteneciendo a un género concreto.
*/

WITH int_gen AS (
    SELECT * FROM {{ ref('int_games__genres_unpivoted') }}
),

dim_juego AS (
    SELECT id_juego, id_steam FROM {{ ref('dim_juego') }}
),

dim_genero AS (
    SELECT id_genero, id_genero_steam FROM {{ ref('dim_genero') }}
)

SELECT
    j.id_juego,
    g.id_genero,
    i.es_primario
FROM int_gen i
JOIN dim_juego j
    ON i.id_steam = j.id_steam
JOIN dim_genero g
    ON i.id_genero_steam = g.id_genero_steam
