{{
    config(
        materialized = 'view'
    )
}}

WITH src_match_player AS (

    SELECT *
    FROM {{ source('kaggle', 'MATCH_PLAYER_RAW') }}

),

-- ── 1. ELIMINAR DUPLICADOS ─────────────────────────────────────────────
deduplicados AS (

    SELECT *
    FROM src_match_player

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY MATCH_ID, PLAYER_ID
        ORDER BY _LOADED_AT ASC
    ) = 1

),

-- ── 2. LIMPIEZA Y CASTEOS ──────────────────────────────────────────────
nulls_normalizados AS (

    SELECT

        TRY_TO_NUMBER(MATCH_ID)      AS match_id,
        TRY_TO_NUMBER(PLAYER_ID)     AS player_id,

        TRY_TO_NUMBER(KILLS)         AS kills,
        TRY_TO_NUMBER(DEATHS)        AS deaths,
        TRY_TO_NUMBER(ASSISTS)       AS assists,
        TRY_TO_NUMBER(SCORE)         AS score

    FROM deduplicados

),

-- ── 3. FLAGS DE CALIDAD ────────────────────────────────────────────────
renamed_casted AS (

    SELECT

        *,

        CASE
            WHEN player_id IS NULL
            THEN TRUE
            ELSE FALSE
        END AS flag_player_invalido,

        CASE
            WHEN kills < 0
              OR deaths < 0
              OR assists < 0
              OR score < 0
            THEN TRUE
            ELSE FALSE
        END AS flag_stats_negativas

    FROM nulls_normalizados

)

SELECT *
FROM renamed_casted
WHERE match_id IS NOT NULL
  AND player_id IS NOT NULL