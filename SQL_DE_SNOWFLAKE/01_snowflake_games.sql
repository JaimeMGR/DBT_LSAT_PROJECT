USE ROLE ACCOUNTADMIN;
USE WAREHOUSE PROYECTO;
USE DATABASE DEV_BRONZE_DB_STEAM;

-- =============================================================================
-- PROYECTO DBT - STEAM GAMES
-- Script: 01_snowflake_setup.sql
-- Descripción: Creación de bases de datos, schemas, stage y tabla raw en Bronze
-- Entornos: DEV y PRO
-- =============================================================================


-- =============================================================================
-- 1. CREACIÓN DE BASES DE DATOS
-- =============================================================================

-- DEV
CREATE DATABASE IF NOT EXISTS DEV_BRONZE_DB_STEAM;
CREATE DATABASE IF NOT EXISTS DEV_SILVER_DB_STEAM;
CREATE DATABASE IF NOT EXISTS DEV_GOLD_DB_STEAM;

-- PRO
CREATE DATABASE IF NOT EXISTS PRO_BRONZE_DB_STEAM;
CREATE DATABASE IF NOT EXISTS PRO_SILVER_DB_STEAM;
CREATE DATABASE IF NOT EXISTS PRO_GOLD_DB_STEAM;

CREATE DATABASE PRO_BRONZE_DB_STEAM
CLONE 
DROP DATABASE DEV_SILVER_DB_STEAM;
DROP DATABASE DEV_GOLD_DB_STEAM;

DROP DATABASE PRO_SILVER_DB_STEAM;
DROP DATABASE PRO_GOLD_DB_STEAM;

-- =============================================================================
-- 2. CREACIÓN DE SCHEMAS EN BRONZE
--    El schema KAGGLE refleja el origen del dataset (Kaggle / Steam)
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS DEV_BRONZE_DB_STEAM.KAGGLE;
CREATE SCHEMA IF NOT EXISTS PRO_BRONZE_DB_STEAM.KAGGLE;


-- =============================================================================
-- 3. FILE FORMAT CSV PARA LA CARGA
--    - Delimitador: coma
--    - Primera fila: cabecera (SKIP_HEADER = 1)
--    - Null si el campo viene vacío
--    - TRIM de espacios en blancos
-- =============================================================================

CREATE OR REPLACE FILE FORMAT DEV_BRONZE_DB_STEAM.KAGGLE.CSV_FORMAT
    TYPE                = 'CSV'
    FIELD_DELIMITER     = ','
    RECORD_DELIMITER    = '\n'
    SKIP_HEADER         = 1
    NULL_IF             = ('', 'NULL', 'null', 'N/A', 'n/a')
    EMPTY_FIELD_AS_NULL = TRUE
    TRIM_SPACE          = TRUE
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    ENCODING            = 'UTF-8'
    COMMENT             = 'Formato CSV para carga de archivos Kaggle Steam';


-- =============================================================================
-- 4. STAGE INTERNO EN DEV BRONZE
--    Usamos un stage interno de Snowflake para subir el CSV manualmente
--    con: PUT file://ruta/local/game_data_all.csv @DEV_BRONZE_DB_STEAM.KAGGLE.STEAM_STAGE;
-- =============================================================================

CREATE OR REPLACE STAGE DEV_BRONZE_DB_STEAM.KAGGLE.STEAM_STAGE
    FILE_FORMAT = DEV_BRONZE_DB_STEAM.KAGGLE.CSV_FORMAT
    COMMENT     = 'Stage interno para carga del dataset Steam (Kaggle)';

-- Para verificar que el archivo se ha subido correctamente:
-- LIST @DEV_BRONZE_DB_STEAM.KAGGLE.STEAM_STAGE;


-- =============================================================================
-- 5. TABLA RAW EN BRONZE (DEV)
--    Todos los campos como STRING/VARCHAR para preservar datos tal cual llegan.
--    La limpieza se realiza en las capas Silver y Gold mediante dbt.
--    La columna sin nombre del CSV (índice) se mapea como ROW_INDEX.
-- =============================================================================

CREATE OR REPLACE TABLE DEV_BRONZE_DB_STEAM.KAGGLE.GAMES_RAW (
    ROW_INDEX               VARCHAR,        -- Índice original del CSV (sin nombre)
    GAME                    VARCHAR,        -- Nombre del juego
    LINK                    VARCHAR,        -- URL de la página en Steam
    RELEASE                 VARCHAR,        -- Fecha de lanzamiento (cruda, puede venir en varios formatos)
    PEAK_PLAYERS            VARCHAR,        -- Pico de jugadores (puede tener comas, NULLs, etc.)
    POSITIVE_REVIEWS        VARCHAR,        -- Reseñas positivas
    NEGATIVE_REVIEWS        VARCHAR,        -- Reseñas negativas
    TOTAL_REVIEWS           VARCHAR,        -- Total reseñas
    RATING                  VARCHAR,        -- Puntuación (float crudo)
    PRIMARY_GENRE           VARCHAR,        -- Género principal
    STORE_GENRES            VARCHAR,        -- Todos los géneros (lista separada por comas dentro del campo)
    PUBLISHER               VARCHAR,        -- Editor(es) - puede ser lista
    DEVELOPER               VARCHAR,        -- Desarrollador(es) - puede ser lista
    DETECTED_TECHNOLOGIES   VARCHAR,        -- Tecnologías detectadas (lista)
    STORE_ASSET_MOD_TIME    VARCHAR,        -- Fecha de modificación del asset en tienda
    REVIEW_PERCENTAGE       VARCHAR,        -- Porcentaje positivo (float crudo)
    PLAYERS_RIGHT_NOW       VARCHAR,        -- Jugadores en este momento
    HOUR_24_PEAK            VARCHAR,        -- Pico en las últimas 24h  (nombre de columna: 24_hour_peak)
    ALL_TIME_PEAK           VARCHAR,        -- Pico histórico
    ALL_TIME_PEAK_DATE      VARCHAR,        -- Fecha del pico histórico

    -- Metadatos de auditoría
    _LOADED_AT              TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    _SOURCE_FILE            VARCHAR
);


-- =============================================================================
-- 6. CARGA DE DATOS DESDE EL STAGE (COPY INTO)
--    Ejecutar DESPUÉS de haber subido el archivo al stage con PUT.
--
--    Paso 1 (desde CLI o SnowSQL):
--      PUT file:///ruta/local/game_data_all.csv
--          @DEV_BRONZE_DB_STEAM.KAGGLE.STEAM_STAGE
--          AUTO_COMPRESS=TRUE;
--
--    Paso 2: ejecutar el COPY INTO siguiente
-- =============================================================================

COPY INTO DEV_BRONZE_DB_STEAM.KAGGLE.GAMES_RAW (
    ROW_INDEX,
    GAME,
    LINK,
    RELEASE,
    PEAK_PLAYERS,
    POSITIVE_REVIEWS,
    NEGATIVE_REVIEWS,
    TOTAL_REVIEWS,
    RATING,
    PRIMARY_GENRE,
    STORE_GENRES,
    PUBLISHER,
    DEVELOPER,
    DETECTED_TECHNOLOGIES,
    STORE_ASSET_MOD_TIME,
    REVIEW_PERCENTAGE,
    PLAYERS_RIGHT_NOW,
    HOUR_24_PEAK,
    ALL_TIME_PEAK,
    ALL_TIME_PEAK_DATE,
    _SOURCE_FILE
)
FROM (
    SELECT
        $1,   -- ROW_INDEX
        $2,   -- GAME
        $3,   -- LINK
        $4,   -- RELEASE
        $5,   -- PEAK_PLAYERS
        $6,   -- POSITIVE_REVIEWS
        $7,   -- NEGATIVE_REVIEWS
        $8,   -- TOTAL_REVIEWS
        $9,   -- RATING
        $10,  -- PRIMARY_GENRE
        $11,  -- STORE_GENRES
        $12,  -- PUBLISHER
        $13,  -- DEVELOPER
        $14,  -- DETECTED_TECHNOLOGIES
        $15,  -- STORE_ASSET_MOD_TIME
        $16,  -- REVIEW_PERCENTAGE
        $17,  -- PLAYERS_RIGHT_NOW
        $18,  -- HOUR_24_PEAK (24_hour_peak)
        $19,  -- ALL_TIME_PEAK
        $20,  -- ALL_TIME_PEAK_DATE
        METADATA$FILENAME
    FROM @DEV_BRONZE_DB_STEAM.KAGGLE.STEAM_STAGE
)
FILE_FORMAT = (FORMAT_NAME = 'DEV_BRONZE_DB_STEAM.KAGGLE.CSV_FORMAT')
ON_ERROR    = 'CONTINUE'    -- Registra errores pero continúa la carga
PURGE       = FALSE;        -- Mantener el archivo en el stage tras la carga

-- Verificar la carga:
-- SELECT COUNT(*) FROM DEV_BRONZE_DB_STEAM.KAGGLE.GAMES_RAW;
-- SELECT * FROM DEV_BRONZE_DB_STEAM.KAGGLE.GAMES_RAW LIMIT 10;


-- =============================================================================
-- 7. CLONING DE DEV A PRO (Bronze)
--    Una vez validada la carga en DEV, se clona a PRO de forma instantánea.
--    El cloning en Snowflake es zero-copy (no duplica almacenamiento).
-- =============================================================================

-- File format
CREATE OR REPLACE FILE FORMAT PRO_BRONZE_DB_STEAM.KAGGLE.CSV_FORMAT
    CLONE DEV_BRONZE_DB_STEAM.KAGGLE.CSV_FORMAT;

-- Stage (los stages internos no se pueden clonar directamente; se recrean)
CREATE OR REPLACE STAGE PRO_BRONZE_DB_STEAM.KAGGLE.STEAM_STAGE
    FILE_FORMAT = PRO_BRONZE_DB_STEAM.KAGGLE.CSV_FORMAT
    COMMENT     = 'Stage interno para carga del dataset Steam (Kaggle) - PRO';

-- Tabla raw clonada desde DEV
CREATE OR REPLACE TABLE PRO_BRONZE_DB_STEAM.KAGGLE.GAMES_RAW
    CLONE DEV_BRONZE_DB_STEAM.KAGGLE.GAMES_RAW;


-- =============================================================================
-- 8. COMPROBACIONES FINALES
-- =============================================================================

-- Ver todas las bases de datos creadas
SHOW DATABASES LIKE '%BRONZE%';
SHOW DATABASES LIKE '%SILVER%';
SHOW DATABASES LIKE '%GOLD%';

-- Ver schemas en Bronze
SHOW SCHEMAS IN DATABASE DEV_BRONZE_DB_STEAM;
SHOW SCHEMAS IN DATABASE PRO_BRONZE_DB_STEAM;

-- Contar registros en las tablas raw
SELECT 'DEV' AS entorno, COUNT(*) AS total_filas FROM DEV_BRONZE_DB_STEAM.KAGGLE.GAMES_RAW
UNION ALL
SELECT 'PRO' AS entorno, COUNT(*) AS total_filas FROM PRO_BRONZE_DB_STEAM.KAGGLE.GAMES_RAW;


USE DATABASE DEV_BRONZE_DB_STEAM;
USE SCHEMA KAGGLE;

select count(*) from match_raw;

INSERT INTO match_raw (MATCH_ID, GAME, GAMEMODE, TEAM_WINNER, FINAL_SCORE,
                   TIME_STARTED, TIME_ENDED, REGION,
                   _LOADED_AT, _SOURCE_FILE)
VALUES
  ('99999001', 'Dota 2',           'arena 3v3',         '1', '20-5',
   '18-05-2026/12:00', '18-05-2026/12:48', 'EUW',
   CURRENT_TIMESTAMP(), 'demo_presentacion');

SELECT COUNT(*) AS total_match FROM MATCH_RAW;

SELECT * 
FROM DEV_BRONZE_DB_STEAM.KAGGLE.MATCH_RAW
WHERE _SOURCE_FILE = 'demo_presentacion';


SELECT COUNT(*) AS total_filas_nuevas
FROM DEV_GOLD_DB_STEAM.MARTS.FCT_MATCH_PLAYER
WHERE _LOADED_AT >= DATEADD(minute, -10, CURRENT_TIMESTAMP());