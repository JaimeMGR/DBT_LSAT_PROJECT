{{ config(materialized = 'view') }}

/*
  MODELO: int_games__game_genres
  CAPA:   Intermediate (Silver)
  ERD:    game_genres (tabla puente)

  Tabla puente entre games y genres. Una fila = un juego perteneciendo
  a un género. PK compuesta (game_id, genre_id).
*/

SELECT DISTINCT
    id_steam                                                    AS game_id,
    id_genero_steam                                             AS genre_id,
    es_primario                                                 AS is_primary
FROM {{ ref('int_games__genres_unpivoted') }}
WHERE id_steam IS NOT NULL
  AND id_genero_steam IS NOT NULL
