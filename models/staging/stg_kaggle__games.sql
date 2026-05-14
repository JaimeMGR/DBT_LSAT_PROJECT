{{
    config(
        materialized = 'view'
    )
}}

/*
  MODELO: stg_kaggle__games
  CAPA:   Staging (Silver)
  ORIGEN: DEV_BRONZE_DB_STEAM.KAGGLE.GAMES_RAW

  Transformaciones aplicadas:
    1. Eliminación de duplicados exactos (QUALIFY ROW_NUMBER)
    2. Limpieza de strings con macro limpiar_texto()
    3. Filtrado de nulos disfrazados (NULL, '', N/A, etc.)
    4. Casteo y parseo de fechas con macro parsear_fecha()
    5. Casteo de campos numéricos con TRY_TO_NUMBER (NULLs seguros)
    6. Extracción del ID de Steam desde el campo LINK
    7. Extracción del ID de género Steam desde PRIMARY_GENRE
    8. Renombrado de columnas a snake_case limpio
*/

WITH src_games AS (

    SELECT *
    FROM {{ source('kaggle', 'GAMES_RAW') }}

),

-- ── 1. ELIMINAR FILAS DUPLICADAS ──────────────────────────────────────────────
deduplicados AS (

    SELECT *
    FROM src_games
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY TRIM(LINK)
        ORDER BY _LOADED_AT ASC
    ) = 1

),

-- ── 2. NULOS DISFRAZADOS → NULL REAL ─────────────────────────────────────────
nulls_normalizados AS (

    SELECT
        ROW_INDEX,
        {{ limpiar_texto('GAME') }}                     AS game_raw,
        {{ limpiar_texto('LINK') }}                     AS link_raw,
        {{ limpiar_texto('RELEASE') }}                  AS release_raw,
        {{ limpiar_texto('PEAK_PLAYERS') }}             AS peak_players_raw,
        {{ limpiar_texto('POSITIVE_REVIEWS') }}         AS positive_reviews_raw,
        {{ limpiar_texto('NEGATIVE_REVIEWS') }}         AS negative_reviews_raw,
        {{ limpiar_texto('TOTAL_REVIEWS') }}            AS total_reviews_raw,
        {{ limpiar_texto('RATING') }}                   AS rating_raw,
        {{ limpiar_texto('PRIMARY_GENRE') }}            AS primary_genre_raw,
        {{ limpiar_texto('STORE_GENRES') }}             AS store_genres_raw,
        {{ limpiar_texto('PUBLISHER') }}                AS publisher_raw,
        {{ limpiar_texto('DEVELOPER') }}                AS developer_raw,
        {{ limpiar_texto('DETECTED_TECHNOLOGIES') }}    AS detected_technologies_raw,
        {{ limpiar_texto('STORE_ASSET_MOD_TIME') }}     AS store_asset_mod_time_raw,
        {{ limpiar_texto('REVIEW_PERCENTAGE') }}        AS review_percentage_raw,
        {{ limpiar_texto('PLAYERS_RIGHT_NOW') }}        AS players_right_now_raw,
        {{ limpiar_texto('HOUR_24_PEAK') }}             AS hour_24_peak_raw,
        {{ limpiar_texto('ALL_TIME_PEAK') }}            AS all_time_peak_raw,
        {{ limpiar_texto('ALL_TIME_PEAK_DATE') }}       AS all_time_peak_date_raw,
        _LOADED_AT,
        _SOURCE_FILE
    FROM deduplicados
    WHERE GAME IS NOT NULL
      AND UPPER(TRIM(GAME)) NOT IN ('NULL', 'N/A', 'NONE', 'NAN')

),

-- ── 3. CASTEOS Y TRANSFORMACIONES ────────────────────────────────────────────
renamed_casted AS (

    SELECT

        TRIM(ROW_INDEX)                                                          AS row_index,

        TRY_TO_NUMBER(
            REGEXP_SUBSTR(link_raw, '/app/([0-9]+)/', 1, 1, 'e', 1)
        )                                                                        AS id_steam,

        TRIM(game_raw)                                                           AS nombre_juego,
        link_raw                                                                 AS link,

        -- Fechas usando macro parsear_fecha()
        {{ parsear_fecha('release_raw') }}                                       AS fecha_lanzamiento,
        {{ parsear_fecha('all_time_peak_date_raw') }}                            AS fecha_pico_historico,
        {{ parsear_fecha('store_asset_mod_time_raw') }}                          AS fecha_mod_tienda,

        -- Numéricos
        TRY_TO_NUMBER(REPLACE(peak_players_raw, ',', ''))                        AS pico_jugadores_reciente,
        TRY_TO_NUMBER(REPLACE(positive_reviews_raw, ',', ''))                    AS resenas_positivas,
        TRY_TO_NUMBER(REPLACE(negative_reviews_raw, ',', ''))                    AS resenas_negativas,
        TRY_TO_NUMBER(REPLACE(total_reviews_raw, ',', ''))                       AS total_resenas,
        TRY_TO_DECIMAL(REPLACE(rating_raw, ',', '.'), 10, 2)                    AS puntuacion,
        TRY_TO_DECIMAL(REPLACE(review_percentage_raw, ',', '.'), 10, 2)         AS porcentaje_positivo,
        TRY_TO_NUMBER(REPLACE(players_right_now_raw, ',', ''))                   AS jugadores_actuales,
        TRY_TO_NUMBER(REPLACE(hour_24_peak_raw, ',', ''))                        AS pico_24h,
        TRY_TO_NUMBER(REPLACE(all_time_peak_raw, ',', ''))                       AS pico_historico,

        -- Género
        TRIM(REGEXP_REPLACE(primary_genre_raw, '\\s*\\([0-9]+\\)', ''))         AS genero_primario,
        TRY_TO_NUMBER(
            REGEXP_SUBSTR(primary_genre_raw, '\\(([0-9]+)\\)', 1, 1, 'e', 1)
        )                                                                        AS id_genero_primario_steam,

        store_genres_raw                                                         AS store_genres,
        TRIM(publisher_raw)                                                      AS publisher,
        TRIM(developer_raw)                                                      AS developer,
        detected_technologies_raw                                                AS detected_technologies,

        -- Segmento usando macro obtener_segmento()
        -- Calculamos total_resenas primero para pasárselo limpio a la macro
        {{ obtener_segmento('TRY_TO_NUMBER(REPLACE(total_reviews_raw, \',\', \'\'))') }} AS segmento,

        _LOADED_AT                                                               AS _loaded_at,
        _SOURCE_FILE                                                             AS _source_file,

        -- Flags de calidad
        CASE
            WHEN release_raw IS NOT NULL
             AND {{ parsear_fecha('release_raw') }} IS NULL
            THEN TRUE ELSE FALSE
        END                                                                      AS flag_fecha_invalida,

        CASE
            WHEN (peak_players_raw IS NOT NULL
                  AND TRY_TO_NUMBER(REPLACE(peak_players_raw, ',', '')) IS NULL)
              OR (rating_raw IS NOT NULL
                  AND TRY_TO_DECIMAL(REPLACE(rating_raw, ',', '.'), 10, 2) IS NULL)
            THEN TRUE ELSE FALSE
        END                                                                      AS flag_numero_invalido

    FROM nulls_normalizados

)

SELECT * FROM renamed_casted
-- Filtramos registros que no tienen ID de Steam válido o nombre de juego
-- Estos registros son irrecuperables y no deben pasar a capas superiores
WHERE id_steam IS NOT NULL
  AND nombre_juego IS NOT NULL
