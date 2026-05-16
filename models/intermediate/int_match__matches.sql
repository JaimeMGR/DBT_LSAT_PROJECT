{{ config(materialized = 'view') }}

/*
  MODELO: int_match__matches
  CAPA:   Intermediate (Silver)
  ERD:    match

  Tabla principal de partidas con todos los FK resueltos:
    - GAME texto       → game_id (Steam ID)
    - GAMEMODE texto   → id_gamemode (surrogate)
    - REGION texto     → id_region (surrogate)
  Las partidas cuyo juego no se encuentra en games quedan con game_id NULL.
*/

WITH stg AS (
    SELECT * FROM {{ ref('stg_kaggle__match') }}
),

games AS (
    SELECT game_id, game_name FROM {{ ref('int_games__games') }}
),

gamemodes AS (
    SELECT id_gamemode, nombre FROM {{ ref('int_match__gamemodes') }}
),

regions AS (
    SELECT id_region, nombre FROM {{ ref('int_match__regions') }}
)

SELECT
    m.match_id,
    g.game_id,
    gm.id_gamemode                                              AS gamemode_id,
    m.team_winner,
    m.final_score,
    m.day_started,
    m.day_ended,
    m.hour_started,
    m.hour_ended,
    r.id_region                                                 AS region
FROM stg m
LEFT JOIN games g       ON m.game = g.game_name
LEFT JOIN gamemodes gm  ON m.gamemode = gm.nombre
LEFT JOIN regions r     ON m.region = r.nombre
WHERE m.match_id IS NOT NULL
