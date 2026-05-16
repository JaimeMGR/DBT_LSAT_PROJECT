{{
    config(
        materialized = 'view'
    )
}}

WITH src_match AS (

    SELECT *
    FROM {{ source('kaggle', 'MATCH_RAW') }}

),

-- ── 1. ELIMINAR DUPLICADOS ─────────────────────────────────────────────
deduplicados AS (

    SELECT *
    FROM src_match

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY MATCH_ID
        ORDER BY _LOADED_AT ASC
    ) = 1

),

-- ── 2. LIMPIEZA DE NULOS Y STRINGS ─────────────────────────────────────
nulls_normalizados AS (

    SELECT

        TRY_TO_NUMBER(MATCH_ID)                     AS match_id,

        {{ limpiar_texto('GAME') }}                 AS game_raw,
        {{ limpiar_texto('GAMEMODE') }}             AS gamemode_raw,
        {{ limpiar_texto('TEAM_WINNER') }}          AS team_winner_raw,
        {{ limpiar_texto('FINAL_SCORE') }}          AS final_score_raw,
        {{ limpiar_texto('TIME_STARTED') }}         AS time_started_raw,
        {{ limpiar_texto('TIME_ENDED') }}           AS time_ended_raw,
        {{ limpiar_texto('REGION') }}               AS region_raw,

        _LOADED_AT,
        _SOURCE_FILE

    FROM deduplicados

),

-- ── 3. NORMALIZACIÓN Y CASTEOS ─────────────────────────────────────────
casted AS (

    SELECT
        match_id,
        TRIM(game_raw) AS game,

        -- GAMEMODE NORMALIZADO
        CASE
            WHEN UPPER(TRIM(gamemode_raw)) IN ('BATTLE ROYALE', 'BATTLE R0YALE') THEN 'Battle Royale'
            WHEN UPPER(TRIM(gamemode_raw)) = 'CAPTURAR LA BANDERA'  THEN 'Capturar la bandera'
            WHEN UPPER(TRIM(gamemode_raw)) = 'TODOS CONTRA TODOS'   THEN 'Todos contra todos'
            WHEN UPPER(TRIM(gamemode_raw)) IN ('ARENA 3V3', '@REN@ 3V3') THEN 'Arena 3v3'
            WHEN UPPER(TRIM(gamemode_raw)) = 'DUELO POR EQUIPOS'    THEN 'Duelo por equipos'
            WHEN UPPER(TRIM(gamemode_raw)) = 'CLASIFICATORIA'       THEN 'Clasificatoria'
            WHEN UPPER(TRIM(gamemode_raw)) = 'SUPERVIVENCIA'        THEN 'Supervivencia'
            WHEN UPPER(TRIM(gamemode_raw)) = 'COOPERATIVO'          THEN 'Cooperativo'
            WHEN UPPER(TRIM(gamemode_raw)) = 'CONQUISTA'            THEN 'Conquista'
            WHEN UPPER(TRIM(gamemode_raw)) = 'DOMINACIÓN'           THEN 'Dominación'
            ELSE NULL
        END AS gamemode,

        TRY_TO_NUMBER(team_winner_raw) AS team_winner,
        TRIM(final_score_raw)          AS final_score,

        TRY_TO_DATE(SPLIT_PART(time_started_raw, '/', 1), 'DD-MM-YYYY') AS day_started,
        TRY_TO_DATE(SPLIT_PART(time_ended_raw,   '/', 1), 'DD-MM-YYYY') AS day_ended,
        TRY_TO_TIME(SPLIT_PART(time_started_raw, '/', 2)) AS hour_started,
        TRY_TO_TIME(SPLIT_PART(time_ended_raw,   '/', 2)) AS hour_ended,

        UPPER(TRIM(region_raw))        AS region,

        gamemode_raw,
        time_started_raw,
        _LOADED_AT,
        _SOURCE_FILE

    FROM nulls_normalizados

),

-- ── 4. FLAGS DE CALIDAD (ya tenemos 'gamemode' y 'day_started' disponibles)
con_flags AS (

    SELECT
        match_id, game, gamemode, team_winner, final_score,
        day_started, day_ended, hour_started, hour_ended, region,
        _LOADED_AT, _SOURCE_FILE,

        CASE WHEN gamemode_raw IS NOT NULL AND gamemode IS NULL
             THEN TRUE ELSE FALSE END AS flag_gamemode_desconocido,

        CASE WHEN time_started_raw IS NOT NULL AND day_started IS NULL
             THEN TRUE ELSE FALSE END AS flag_fecha_invalida

    FROM casted

)

SELECT * FROM con_flags WHERE match_id IS NOT NULL