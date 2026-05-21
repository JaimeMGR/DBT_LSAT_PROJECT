
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE PROYECTO;
USE DATABASE DEV_BRONZE_DB_STEAM;
USE SCHEMA KAGGLE;

-- Columnas de int_games__games
SELECT * FROM DEV_SILVER_DB_STEAM.INTERMEDIATE.INT_GAMES__GAMES LIMIT 1;

-- Columnas de stg_kaggle__match_player
SELECT * FROM DEV_SILVER_DB_STEAM.STAGING.STG_KAGGLE__MATCH_PLAYER LIMIT 1;

-- Conteos de cada tabla Gold
SELECT 'fct_juego' t, COUNT(*) FROM DEV_GOLD_DB_STEAM.MARTS.FCT_JUEGO
UNION ALL SELECT 'fct_match_player', COUNT(*) FROM DEV_GOLD_DB_STEAM.MARTS.FCT_MATCH_PLAYER
UNION ALL SELECT 'dim_jugador', COUNT(*) FROM DEV_GOLD_DB_STEAM.MARTS.DIM_JUGADOR
UNION ALL SELECT 'dim_fecha', COUNT(*) FROM DEV_GOLD_DB_STEAM.MARTS.DIM_FECHA;

-- Esperado aprox: fct_juego ~66k, fct_match_player ~16k,
--                 dim_jugador 200, dim_fecha ~10.957 (date spine 2000-2030)

-- Adelanto del caso de uso: top 10 jugadores por KDA acumulado
SELECT
    j.NICKNAME,
    SUM(f.KILLS)   AS kills,
    SUM(f.DEATHS)  AS deaths,
    SUM(f.ASSISTS) AS assists,
    ROUND((SUM(f.KILLS) + SUM(f.ASSISTS)) / NULLIF(SUM(f.DEATHS), 0), 2) AS kda
FROM DEV_GOLD_DB_STEAM.MARTS.FCT_MATCH_PLAYER f
JOIN DEV_GOLD_DB_STEAM.MARTS.DIM_JUGADOR j ON f.ID_JUGADOR = j.ID_JUGADOR
GROUP BY 1
ORDER BY kda DESC
LIMIT 10;

DROP TABLE IF EXISTS DEV_GOLD_DB_STEAM.MARTS.FCT_ACTIVIDAD_JUEGO;
DROP TABLE IF EXISTS PRO_GOLD_DB_STEAM.MARTS.FCT_ACTIVIDAD_JUEGO;

SELECT * FROM DEV_GOLD_DB_STEAM.MARTS.DIM_DESARROLLADOR ORDER BY TOTAL_JUEGOS DESC;

-- ¿Cuántas partidas tienen modo de juego que no se pudo normalizar?
SELECT
    COUNT(*)                                                    AS total,
    SUM(CASE WHEN flag_gamemode_desconocido THEN 1 ELSE 0 END)  AS gamemode_malo,
    SUM(CASE WHEN flag_fecha_invalida THEN 1 ELSE 0 END)        AS fecha_mala
FROM DEV_SILVER_DB_STEAM.STAGING.STG_KAGGLE__MATCH;

-- ¿Cuántos jugadores con fecha de nacimiento corrupta?
SELECT
    COUNT(*)                                              AS total,
    SUM(CASE WHEN flag_age_invalida THEN 1 ELSE 0 END)    AS edad_mala
FROM DEV_SILVER_DB_STEAM.STAGING.STG_KAGGLE__PLAYER;

SELECT 'Bronze match'  t, COUNT(*) FROM DEV_BRONZE_DB_STEAM.KAGGLE.MATCH_RAW
UNION ALL SELECT 'Silver match', COUNT(*) FROM DEV_SILVER_DB_STEAM.STAGING.STG_KAGGLE__MATCH
UNION ALL SELECT 'Bronze match_player', COUNT(*) FROM DEV_BRONZE_DB_STEAM.KAGGLE.MATCH_PLAYER_RAW
UNION ALL SELECT 'Gold fct_match_player', COUNT(*) FROM DEV_GOLD_DB_STEAM.MARTS.FCT_MATCH_PLAYER;

-- KDA: ningún jugador con muertes negativas o kills absurdas
SELECT MIN(kills), MAX(kills), MIN(deaths), MAX(deaths)
FROM DEV_GOLD_DB_STEAM.MARTS.FCT_MATCH_PLAYER;

-- Partidas: ninguna que termine antes de empezar
SELECT COUNT(*) AS partidas_imposibles
FROM DEV_SILVER_DB_STEAM.INTERMEDIATE.INT_MATCH__MATCHES
WHERE day_ended < day_started;

-- Modos de juego: ver la lista final, no debe haber typos
SELECT DISTINCT nombre FROM DEV_GOLD_DB_STEAM.MARTS.DIM_GAMEMODE;

-- Regiones: deben ser exactamente 6
SELECT DISTINCT nombre FROM DEV_GOLD_DB_STEAM.MARTS.DIM_REGION;