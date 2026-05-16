{{
    config(
        materialized     = 'incremental',
        unique_key       = 'id_match_player',
        on_schema_change = 'sync_all_columns'
    )
}}

/*
  HECHOS: fct_match_player
  MART:   Partidas multijugador
  ORIGEN: stg_kaggle__match_player + int_match__matches

  Granularidad: una fila = un jugador en una partida (~16.050 filas).
  Es la tabla base del caso de uso 'Top 10 jugadores por KDA'.

  Materialización incremental: las partidas solo crecen, nunca se
  modifican las pasadas, así que solo procesamos las nuevas.

  Métrica calculada:
    - kda: (kills + assists) / deaths   (si deaths = 0, kills + assists)
*/

WITH match_player AS (
    SELECT * FROM {{ ref('stg_kaggle__match_player') }}

    {% if is_incremental() %}
        WHERE _loaded_at > (SELECT MAX(_loaded_at) FROM {{ this }})
    {% endif %}
),

matches AS (
    SELECT * FROM {{ ref('int_match__matches') }}
)

SELECT
    -- ── CLAVE Y FKs ──────────────────────────────────────────────────────────
    {{ dbt_utils.generate_surrogate_key(['mp.match_id', 'mp.player_id']) }} AS id_match_player,
    {{ dbt_utils.generate_surrogate_key(['mp.player_id']) }}                AS id_jugador,
    mp.match_id,
    {{ dbt_utils.generate_surrogate_key(['m.game_id']) }}                   AS id_juego,
    m.gamemode_id                                                           AS id_gamemode,
    m.region                                                                AS id_region,
    {{ dbt_utils.generate_surrogate_key(['m.day_started']) }}               AS id_fecha_partida,

    -- ── MÉTRICAS KDA ─────────────────────────────────────────────────────────
    mp.kills,
    mp.deaths,
    mp.assists,
    mp.score,

    -- KDA de la partida: (kills + asistencias) / muertes
    CASE
        WHEN mp.deaths = 0 THEN mp.kills + mp.assists
        ELSE ROUND((mp.kills + mp.assists) / mp.deaths::FLOAT, 2)
    END                                                                     AS kda,

    -- ── ATRIBUTOS DE LA PARTIDA ──────────────────────────────────────────────
    m.team_winner,
    m.final_score,

    -- ── AUDITORÍA ────────────────────────────────────────────────────────────
    mp._loaded_at

FROM match_player mp
LEFT JOIN matches m ON mp.match_id = m.match_id
