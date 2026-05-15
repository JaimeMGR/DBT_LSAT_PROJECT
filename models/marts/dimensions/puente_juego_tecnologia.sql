{{
    config(
        materialized = 'table'
    )
}}

/*
  MODELO: puente_juego_tecnologia
  CAPA:   Marts / Gold
  DESCRIPCIÓN: Tabla puente que resuelve la relación muchos a muchos
               entre DIM_JUEGO y DIM_TECNOLOGIA.
               Una fila = un juego usando una tecnología concreta.
*/

WITH int_tech AS (
    SELECT * FROM {{ ref('int_games__technologies_unpivoted') }}
),

dim_juego AS (
    SELECT id_juego, id_steam FROM {{ ref('dim_juego') }}
),

dim_tecnologia AS (
    SELECT id_tecnologia, tipo_tecnologia, nombre FROM {{ ref('dim_tecnologia') }}
)

SELECT
    j.id_juego,
    t.id_tecnologia
FROM int_tech i
JOIN dim_juego j
    ON i.id_steam = j.id_steam
JOIN dim_tecnologia t
    ON i.tipo_tecnologia = t.tipo_tecnologia
   AND i.nombre_tecnologia = t.nombre
