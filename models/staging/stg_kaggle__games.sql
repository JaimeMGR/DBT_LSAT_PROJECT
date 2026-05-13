{{
    config(
        materialized = 'view'
    )
}}

/*
  MODELO: stg_kaggle__games
  CAPA:   Staging (Silver)
  ORIGEN: DEV_BRONZE_DB.KAGGLE.GAMES_RAW

  Transformaciones aplicadas:
    1. Eliminación de duplicados exactos (QUALIFY ROW_NUMBER)
    2. Limpieza de strings: TRIM + UPPER/LOWER donde corresponde
    3. Filtrado de nulos disfrazados (NULL, '', N/A, etc.)
    4. Casteo y parseo de fechas con múltiples formatos
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
-- Mantenemos solo la primera ocurrencia de cada juego por su link
deduplicados AS (

    SELECT *
    FROM src_games
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY TRIM(LINK)
        ORDER BY _LOADED_AT ASC
    ) = 1

),

-- ── 2. NULOS DISFRAZADOS → NULL REAL ─────────────────────────────────────────
-- Los valores 'NULL', 'null', 'N/A', '' y ' ' se normalizan a NULL
nulls_normalizados AS (

    SELECT
        ROW_INDEX,
        NULLIF(TRIM(GAME),   '')                                        AS game_raw,
        NULLIF(TRIM(LINK),   '')                                        AS link_raw,
        NULLIF(TRIM(RELEASE),'')                                        AS release_raw,
        NULLIF(TRIM(PEAK_PLAYERS),        '')                           AS peak_players_raw,
        NULLIF(TRIM(POSITIVE_REVIEWS),    '')                           AS positive_reviews_raw,
        NULLIF(TRIM(NEGATIVE_REVIEWS),    '')                           AS negative_reviews_raw,
        NULLIF(TRIM(TOTAL_REVIEWS),       '')                           AS total_reviews_raw,
        NULLIF(TRIM(RATING),              '')                           AS rating_raw,
        NULLIF(TRIM(PRIMARY_GENRE),       '')                           AS primary_genre_raw,
        NULLIF(TRIM(STORE_GENRES),        '')                           AS store_genres_raw,
        NULLIF(TRIM(PUBLISHER),           '')                           AS publisher_raw,
        NULLIF(TRIM(DEVELOPER),           '')                           AS developer_raw,
        NULLIF(TRIM(DETECTED_TECHNOLOGIES),'')                          AS detected_technologies_raw,
        NULLIF(TRIM(STORE_ASSET_MOD_TIME),'')                           AS store_asset_mod_time_raw,
        NULLIF(TRIM(REVIEW_PERCENTAGE),   '')                           AS review_percentage_raw,
        NULLIF(TRIM(PLAYERS_RIGHT_NOW),   '')                           AS players_right_now_raw,
        NULLIF(TRIM(HOUR_24_PEAK),        '')                           AS hour_24_peak_raw,
        NULLIF(TRIM(ALL_TIME_PEAK),       '')                           AS all_time_peak_raw,
        NULLIF(TRIM(ALL_TIME_PEAK_DATE),  '')                           AS all_time_peak_date_raw,
        _LOADED_AT,
        _SOURCE_FILE
    FROM deduplicados
    -- Excluir filas con nulos disfrazados en los valores de relleno más comunes
    WHERE UPPER(TRIM(GAME)) NOT IN ('NULL', 'N/A', 'NONE', 'NAN')
      OR GAME IS NULL

),

-- ── 3. LIMPIEZA DE STRINGS + CASTEOS TIPADOS ──────────────────────────────────
renamed_casted AS (

    SELECT

        -- Identificadores
        TRIM(ROW_INDEX)                                                          AS row_index,

        -- Extrae el ID numérico de Steam desde el link: '/app/2231450/' → 2231450
        TRY_TO_NUMBER(
            REGEXP_SUBSTR(link_raw, '/app/([0-9]+)/', 1, 1, 'e', 1)
        )                                                                        AS id_steam,

        -- Nombre del juego: solo TRIM (preservamos capitalización original limpia)
        TRIM(game_raw)                                                           AS nombre_juego,

        -- Link completo
        link_raw                                                                 AS link,

        -- ── FECHAS ──────────────────────────────────────────────────────────
        -- Intenta parsear múltiples formatos: YYYY-MM-DD, DD/MM/YYYY, MM-DD-YY, etc.
        COALESCE(
            TRY_TO_DATE(release_raw, 'YYYY-MM-DD'),
            TRY_TO_DATE(release_raw, 'DD/MM/YYYY'),
            TRY_TO_DATE(release_raw, 'MM-DD-YYYY'),
            TRY_TO_DATE(release_raw, 'DD-MM-YY'),
            TRY_TO_DATE(release_raw, 'DD-MM-YYYY')
        )                                                                        AS fecha_lanzamiento,

        COALESCE(
            TRY_TO_DATE(all_time_peak_date_raw, 'YYYY-MM-DD'),
            TRY_TO_DATE(all_time_peak_date_raw, 'DD/MM/YYYY'),
            TRY_TO_DATE(all_time_peak_date_raw, 'MM-DD-YYYY'),
            TRY_TO_DATE(all_time_peak_date_raw, 'DD-MM-YY'),
            TRY_TO_DATE(all_time_peak_date_raw, 'DD-MM-YYYY')
        )                                                                        AS fecha_pico_historico,

        COALESCE(
            TRY_TO_DATE(store_asset_mod_time_raw, 'YYYY-MM-DD'),
            TRY_TO_DATE(store_asset_mod_time_raw, 'DD/MM/YYYY'),
            TRY_TO_DATE(store_asset_mod_time_raw, 'MM-DD-YYYY'),
            TRY_TO_DATE(store_asset_mod_time_raw, 'DD-MM-YY'),
            TRY_TO_DATE(store_asset_mod_time_raw, 'DD-MM-YYYY')
        )                                                                        AS fecha_mod_tienda,

        -- ── NUMÉRICOS ────────────────────────────────────────────────────────
        -- TRY_TO_NUMBER retorna NULL si no puede convertir (en vez de error)
        -- REPLACE(',','') para limpiar separadores de miles como "1,234"
        TRY_TO_NUMBER(REPLACE(peak_players_raw, ',', ''))                        AS pico_jugadores_reciente,
        TRY_TO_NUMBER(REPLACE(positive_reviews_raw, ',', ''))                    AS resenas_positivas,
        TRY_TO_NUMBER(REPLACE(negative_reviews_raw, ',', ''))                    AS resenas_negativas,
        TRY_TO_NUMBER(REPLACE(total_reviews_raw, ',', ''))                       AS total_resenas,
        TRY_TO_DECIMAL(REPLACE(rating_raw, ',', '.'), 10, 2)                    AS puntuacion,
        TRY_TO_DECIMAL(REPLACE(review_percentage_raw, ',', '.'), 10, 2)         AS porcentaje_positivo,
        TRY_TO_NUMBER(REPLACE(players_right_now_raw, ',', ''))                   AS jugadores_actuales,
        TRY_TO_NUMBER(REPLACE(hour_24_peak_raw, ',', ''))                        AS pico_24h,
        TRY_TO_NUMBER(REPLACE(all_time_peak_raw, ',', ''))                       AS pico_historico,

        -- ── GÉNERO ───────────────────────────────────────────────────────────
        -- Extrae el nombre del género: "Action (1)" → "Action"
        TRIM(REGEXP_REPLACE(primary_genre_raw, '\\s*\\([0-9]+\\)', ''))         AS genero_primario,

        -- Extrae el ID numérico de Steam del género: "Action (1)" → 1
        TRY_TO_NUMBER(
            REGEXP_SUBSTR(primary_genre_raw, '\\(([0-9]+)\\)', 1, 1, 'e', 1)
        )                                                                        AS id_genero_primario_steam,

        -- Lista completa de géneros (se procesará en la capa intermedia)
        store_genres_raw                                                         AS store_genres,

        -- ── ENTIDADES TEXTO ──────────────────────────────────────────────────
        -- Solo TRIM; la normalización de mayúsculas se hace en marts si es necesario
        TRIM(publisher_raw)                                                      AS publisher,
        TRIM(developer_raw)                                                      AS developer,

        -- Lista de tecnologías separada por punto y coma (se procesará en intermedia)
        detected_technologies_raw                                                AS detected_technologies,

        -- ── METADATOS ────────────────────────────────────────────────────────
        _LOADED_AT                                                               AS _loaded_at,
        _SOURCE_FILE                                                             AS _source_file,

        -- Flag de calidad: indica si la fecha de lanzamiento no pudo parsearse
        CASE
            WHEN release_raw IS NOT NULL
             AND COALESCE(
                    TRY_TO_DATE(release_raw, 'YYYY-MM-DD'),
                    TRY_TO_DATE(release_raw, 'DD/MM/YYYY'),
                    TRY_TO_DATE(release_raw, 'MM-DD-YYYY'),
                    TRY_TO_DATE(release_raw, 'DD-MM-YY'),
                    TRY_TO_DATE(release_raw, 'DD-MM-YYYY')
                ) IS NULL
            THEN TRUE
            ELSE FALSE
        END                                                                      AS flag_fecha_invalida,

        -- Flag de calidad: indica si algún campo numérico clave vino corrupto
        CASE
            WHEN (peak_players_raw IS NOT NULL
                  AND TRY_TO_NUMBER(REPLACE(peak_players_raw, ',', '')) IS NULL)
              OR (rating_raw IS NOT NULL
                  AND TRY_TO_DECIMAL(REPLACE(rating_raw, ',', '.'), 10, 2) IS NULL)
            THEN TRUE
            ELSE FALSE
        END                                                                      AS flag_numero_invalido

    FROM nulls_normalizados

)

SELECT * FROM renamed_casted
