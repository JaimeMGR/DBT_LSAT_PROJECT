USE ROLE ACCOUNTADMIN;
USE WAREHOUSE PROYECTO;
USE DATABASE DEV_BRONZE_DB_STEAM;
USE SCHEMA KAGGLE;

-- =============================================================================
-- PROYECTO DBT - STEAM GAMES
-- Script: 02_snowflake_multiplayer.sql
-- Descripción: Añade las tablas raw de partidas, jugadores y KDA.
--              Reutiliza el stage STEAM_STAGE y el FILE FORMAT CSV_FORMAT
--              ya creados en el script 01.
-- Entornos: DEV y PRO
-- =============================================================================



-- =============================================================================
-- 1. TABLA MATCH — Partidas multijugador
-- =============================================================================
CREATE OR REPLACE TABLE DEV_BRONZE_DB_STEAM.KAGGLE.MATCH_RAW (
    MATCH_ID         VARCHAR,        -- ID único de la partida
    GAME             VARCHAR,        -- Nombre del juego (a resolver por JOIN en Silver)
    GAMEMODE         VARCHAR,        -- Modo de juego (sucio: mayúsculas, typos)
    TEAM_WINNER      VARCHAR,        -- Equipo ganador (1 o 2)
    FINAL_SCORE      VARCHAR,        -- Puntuación final 'X-Y'
    TIME_STARTED     VARCHAR,        -- Inicio (formato DD-MM-YYYY/HH:MM)
    TIME_ENDED       VARCHAR,        -- Fin   (formato DD-MM-YYYY/HH:MM)
    REGION           VARCHAR,        -- NA / EUW / EUNE / SA / ASIA / OCE (sucio)

    _LOADED_AT       TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    _SOURCE_FILE     VARCHAR
);


-- =============================================================================
-- 2. TABLA PLAYER — Jugadores
-- =============================================================================
CREATE OR REPLACE TABLE DEV_BRONZE_DB_STEAM.KAGGLE.PLAYER_RAW (
    PLAYER_ID                VARCHAR,    -- ID único del jugador
    NICKNAME                 VARCHAR,    -- Nombre público en Steam
    AGE                      VARCHAR,    -- Fecha de nacimiento (no edad)
    MAIL                     VARCHAR,    -- Email (se hashea con MD5 en Silver)
    DATE_CREATION_PROFILE    VARCHAR,    -- Fecha creación de cuenta

    _LOADED_AT               TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    _SOURCE_FILE             VARCHAR
);


-- =============================================================================
-- 3. TABLA MATCH_PLAYER — Detalle KDA por partida
-- =============================================================================
CREATE OR REPLACE TABLE DEV_BRONZE_DB_STEAM.KAGGLE.MATCH_PLAYER_RAW (
    MATCH_ID         VARCHAR,        -- FK → MATCH
    PLAYER_ID        VARCHAR,        -- FK → PLAYER
    KILLS            VARCHAR,        -- Eliminaciones
    DEATHS           VARCHAR,        -- Muertes
    ASSISTS          VARCHAR,        -- Asistencias
    SCORE            VARCHAR,        -- Puntuación final del jugador

    _LOADED_AT       TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    _SOURCE_FILE     VARCHAR
);


-- =============================================================================
-- 4. CARGA DE DATOS DESDE EL STAGE
-- Pasos previos en SnowSQL o desde la UI de Snowflake (Data → Stages):
--
--   PUT file:///ruta/local/matches.csv       @DEV_BRONZE_DB_STEAM.KAGGLE.STEAM_STAGE_RAW AUTO_COMPRESS=TRUE;
--   PUT file:///ruta/local/players.csv       @DEV_BRONZE_DB_STEAM.KAGGLE.STEAM_STAGE_RAW AUTO_COMPRESS=TRUE;
--   PUT file:///ruta/local/match_player.csv  @DEV_BRONZE_DB_STEAM.KAGGLE.STEAM_STAGE_RAW AUTO_COMPRESS=TRUE;
--
-- Verifica que se han subido:
--   LIST @DEV_BRONZE_DB_STEAM.KAGGLE.STEAM_STAGE_RAW;
-- =============================================================================

-- ── MATCH ────────────────────────────────────────────────────────────────────
COPY INTO DEV_BRONZE_DB_STEAM.KAGGLE.MATCH_RAW (
    MATCH_ID, GAME, GAMEMODE, TEAM_WINNER, FINAL_SCORE,
    TIME_STARTED, TIME_ENDED, REGION, _SOURCE_FILE
)
FROM (
    SELECT $1, $2, $3, $4, $5, $6, $7, $8, METADATA$FILENAME
    FROM @DEV_BRONZE_DB_STEAM.KAGGLE.STEAM_STAGE/matches.csv
)
FILE_FORMAT = (FORMAT_NAME = 'DEV_BRONZE_DB_STEAM.KAGGLE.CSV_FORMAT')
ON_ERROR    = 'CONTINUE';

-- ── PLAYER ───────────────────────────────────────────────────────────────────
COPY INTO DEV_BRONZE_DB_STEAM.KAGGLE.PLAYER_RAW (
    PLAYER_ID, NICKNAME, AGE, MAIL, DATE_CREATION_PROFILE, _SOURCE_FILE
)
FROM (
    SELECT $1, $2, $3, $4, $5, METADATA$FILENAME
    FROM @DEV_BRONZE_DB_STEAM.KAGGLE.STEAM_STAGE/players.csv
)
FILE_FORMAT = (FORMAT_NAME = 'DEV_BRONZE_DB_STEAM.KAGGLE.CSV_FORMAT')
ON_ERROR    = 'CONTINUE';

-- ── MATCH_PLAYER ─────────────────────────────────────────────────────────────
COPY INTO DEV_BRONZE_DB_STEAM.KAGGLE.MATCH_PLAYER_RAW (
    MATCH_ID, PLAYER_ID, KILLS, DEATHS, ASSISTS, SCORE, _SOURCE_FILE
)
FROM (
    SELECT $1, $2, $3, $4, $5, $6, METADATA$FILENAME
    FROM @DEV_BRONZE_DB_STEAM.KAGGLE.STEAM_STAGE/match_player.csv
)
FILE_FORMAT = (FORMAT_NAME = 'DEV_BRONZE_DB_STEAM.KAGGLE.CSV_FORMAT')
ON_ERROR    = 'CONTINUE';


-- =============================================================================
-- 5. VERIFICACIÓN
-- =============================================================================
SELECT 'MATCH'        AS tabla, COUNT(*) AS filas FROM DEV_BRONZE_DB_STEAM.KAGGLE.MATCH_RAW
UNION ALL
SELECT 'PLAYER',       COUNT(*) FROM DEV_BRONZE_DB_STEAM.KAGGLE.PLAYER_RAW
UNION ALL
SELECT 'MATCH_PLAYER', COUNT(*) FROM DEV_BRONZE_DB_STEAM.KAGGLE.MATCH_PLAYER_RAW;

-- Esperado:
--   MATCH         → 2.000
--   PLAYER        → 200
--   MATCH_PLAYER  → 16.050

-- Echar un vistazo a los datos
SELECT * FROM DEV_BRONZE_DB_STEAM.KAGGLE.MATCH_RAW        LIMIT 5;
SELECT * FROM DEV_BRONZE_DB_STEAM.KAGGLE.PLAYER_RAW       LIMIT 5;
SELECT * FROM DEV_BRONZE_DB_STEAM.KAGGLE.MATCH_PLAYER_RAW LIMIT 5;


-- =============================================================================
-- 6. CLONING A PRO
-- =============================================================================
CREATE OR REPLACE TABLE PRO_BRONZE_DB_STEAM.KAGGLE.MATCH_RAW
    CLONE DEV_BRONZE_DB_STEAM.KAGGLE.MATCH_RAW;

CREATE OR REPLACE TABLE PRO_BRONZE_DB_STEAM.KAGGLE.PLAYER_RAW
    CLONE DEV_BRONZE_DB_STEAM.KAGGLE.PLAYER_RAW;

CREATE OR REPLACE TABLE PRO_BRONZE_DB_STEAM.KAGGLE.MATCH_PLAYER_RAW
    CLONE DEV_BRONZE_DB_STEAM.KAGGLE.MATCH_PLAYER_RAW;

-- Verificación de PRO
SELECT 'MATCH'        AS tabla, COUNT(*) FROM PRO_BRONZE_DB_STEAM.KAGGLE.MATCH_RAW
UNION ALL
SELECT 'PLAYER',       COUNT(*) FROM PRO_BRONZE_DB_STEAM.KAGGLE.PLAYER_RAW
UNION ALL
SELECT 'MATCH_PLAYER', COUNT(*) FROM PRO_BRONZE_DB_STEAM.KAGGLE.MATCH_PLAYER_RAW;


