{{ config(materialized = 'view') }}

/*
  MODELO: int_games__game_technologies
  CAPA:   Intermediate (Silver)
  ERD:    game_technologies

  Tabla puente entre games y technologies. Resuelve el FK a technology_types.
  Una fila = un juego usando una tecnología.
*/

WITH unpivoted AS (
    SELECT * FROM {{ ref('int_games__technologies_unpivoted') }}
    WHERE id_steam IS NOT NULL
      AND tipo_tecnologia IS NOT NULL
      AND nombre_tecnologia IS NOT NULL
),

tech_types AS (
    SELECT type_id, type_name FROM {{ ref('int_games__technology_types') }}
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['id_steam', 'tipo_tecnologia', 'nombre_tecnologia']) }} AS game_technology_id,
    u.id_steam                                                  AS game_id,
    t.type_id                                                   AS technology_type_id,
    u.nombre_tecnologia                                         AS technology_name
FROM unpivoted u
LEFT JOIN tech_types t
       ON u.tipo_tecnologia = t.type_name
