{{
    config(
        materialized = 'view'
    )
}}

/*
  MODELO: stg_kaggle__player
  CAPA:   Staging (Silver)
  ORIGEN: DEV_BRONZE_DB_STEAM.KAGGLE.PLAYER_RAW

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

WITH src_players AS (

    SELECT *
    FROM {{ source('kaggle', 'PLAYER_RAW') }}

),

-- ── 1. ELIMINAR FILAS DUPLICADAS ──────────────────────────────────────────────
deduplicados AS (


    SELECT *
    FROM src_players
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY PLAYER_ID                
        ORDER BY _LOADED_AT ASC
    ) = 1
),

-- ── 2. NULOS DISFRAZADOS → NULL REAL ─────────────────────────────────────────
nulls_normalizados AS (
    SELECT
        PLAYER_ID                                       AS player_id_raw,
        {{ limpiar_texto('NICKNAME') }}                 AS nickname_raw,
        {{ limpiar_texto('AGE') }}                      AS age_raw,
        {{ limpiar_texto('MAIL') }}                     AS mail_raw,
        {{ limpiar_texto('DATE_CREATION_PROFILE') }}    AS date_creation_raw,
        _LOADED_AT,
        _SOURCE_FILE
    FROM deduplicados
),

-- ── 3. CASTEOS Y TRANSFORMACIONES ────────────────────────────────────────────
renamed_casted AS (
    SELECT
        TRY_TO_NUMBER(player_id_raw)                    AS player_id,
        TRIM(nickname_raw)                              AS nickname,
        {{ parsear_fecha('age_raw') }}                  AS fecha_nacimiento,

        -- Calculamos edad real desde la fecha de nacimiento
        DATEDIFF('year', {{ parsear_fecha('age_raw') }}, CURRENT_DATE())  AS edad,

        -- Hash MD5 del email para anonimizar
        CASE
            WHEN REGEXP_LIKE(LOWER(TRIM(mail_raw)),
                             '^[a-z0-9._%+-]+@[a-z0-9.-]+\\.[a-z]{2,}$')
            THEN MD5(LOWER(TRIM(mail_raw)))
            ELSE NULL
        END                                             AS mail_hash,

        TRY_TO_TIMESTAMP(date_creation_raw)             AS fecha_creacion_perfil,

        CASE WHEN age_raw IS NOT NULL
              AND {{ parsear_fecha('age_raw') }} IS NULL
             THEN TRUE ELSE FALSE END                   AS flag_age_invalida,

        _LOADED_AT,
        _SOURCE_FILE

    FROM nulls_normalizados
)

SELECT * FROM renamed_casted
-- Filtramos registros que no tienen ID de Steam válido o nombre de juego
-- Estos registros son irrecuperables y no deben pasar a capas superiores
WHERE player_id IS NOT NULL
  AND mail_hash  IS NOT NULL
