-- ============================================================================
-- 1. CONFIGURACIÓN INICIAL
-- ============================================================================

-- Cambiar zona horaria a Madrid para esta sesión
ALTER SESSION SET TIMEZONE = 'Europe/Madrid';

-- Seleccionar la base de datos y schema de trabajo
USE DATABASE PRO_BRONZE_DB_STEAM;
USE SCHEMA KAGGLE;

-- Verificar que la hora ya es la de Madrid
SELECT CURRENT_TIMESTAMP() AS hora_actual_madrid;


-- ============================================================================
-- 2. LIMPIEZA DE PRUEBAS ANTERIORES
-- ============================================================================

-- 2.1 Borrar las filas de prueba en Bronze
DELETE FROM PRO_BRONZE_DB_STEAM.KAGGLE.MATCH_RAW
WHERE _SOURCE_FILE = 'demo_presentacion';

DELETE FROM PRO_BRONZE_DB_STEAM.KAGGLE.MATCH_PLAYER_RAW
WHERE _SOURCE_FILE = 'demo_presentacion';

-- 2.2 Borrar las filas de prueba que ya subieron a Gold
-- (filtramos por MATCH_ID porque _SOURCE_FILE no se propaga hasta Gold)
DELETE FROM PRO_GOLD_DB_STEAM.MARTS.FCT_MATCH_PLAYER
WHERE MATCH_ID IN ('99999001', '99999002', '99999003');


-- ============================================================================
-- 3. VERIFICACIÓN DEL ESTADO BASE
-- ============================================================================

-- Confirmar que no queda nada de pruebas anteriores
SELECT 
    (SELECT COUNT(*) FROM PRO_BRONZE_DB_STEAM.KAGGLE.MATCH_RAW 
     WHERE _SOURCE_FILE = 'demo_presentacion')          AS pruebas_bronze_match,
    (SELECT COUNT(*) FROM PRO_BRONZE_DB_STEAM.KAGGLE.MATCH_PLAYER_RAW 
     WHERE _SOURCE_FILE = 'demo_presentacion')          AS pruebas_bronze_stats,
    (SELECT COUNT(*) FROM PRO_GOLD_DB_STEAM.MARTS.FCT_MATCH_PLAYER 
     WHERE MATCH_ID IN ('99999001','99999002','99999003')) AS pruebas_gold;
-- Los tres números deben dar 0.

-- Estado base antes de empezar la demo
SELECT 
    COUNT(*) AS total_filas_gold,
    MAX(_LOADED_AT) AS ultima_carga
FROM PRO_GOLD_DB_STEAM.MARTS.FCT_MATCH_PLAYER;
-- Apunta estos dos números — son el "antes" de la demo.


-- ============================================================================
-- 4. INGESTA DE DATOS NUEVOS EN BRONZE
-- ============================================================================

-- 4.1 Insertar 3 partidas nuevas en MATCH_RAW
INSERT INTO PRO_BRONZE_DB_STEAM.KAGGLE.MATCH_RAW 
    (MATCH_ID, GAME, GAMEMODE, TEAM_WINNER, FINAL_SCORE,
     TIME_STARTED, TIME_ENDED, REGION,
     _LOADED_AT, _SOURCE_FILE)
VALUES
    ('99999001', 'Dota 2',        'arena 3v3',         '1', '20-5',
     '18-05-2026/14:00', '18-05-2026/14:35', 'EUW',
     CURRENT_TIMESTAMP(), 'demo_presentacion'),
    ('99999002', 'Apex Legends',  'battle royale',     '2', '0-12',
     '18-05-2026/15:00', '18-05-2026/15:22', 'NA',
     CURRENT_TIMESTAMP(), 'demo_presentacion'),
    ('99999003', 'Rocket League', 'duelo por equipos', '1', '5-3',
     '18-05-2026/16:00', '18-05-2026/16:15', 'SA',
     CURRENT_TIMESTAMP(), 'demo_presentacion');

-- 4.2 Insertar las estadísticas de los jugadores en MATCH_PLAYER_RAW
INSERT INTO PRO_BRONZE_DB_STEAM.KAGGLE.MATCH_PLAYER_RAW 
    (MATCH_ID, PLAYER_ID, KILLS, DEATHS, ASSISTS, SCORE,
     _LOADED_AT, _SOURCE_FILE)
VALUES
    -- Partida 99999001 (Dota 2)
    ('99999001', '1',   '20', '3',  '15', '2800', CURRENT_TIMESTAMP(), 'demo_presentacion'),
    ('99999001', '2',   '8',  '12', '5',  '1200', CURRENT_TIMESTAMP(), 'demo_presentacion'),
    ('99999001', '15',  '12', '7',  '9',  '1900', CURRENT_TIMESTAMP(), 'demo_presentacion'),
    ('99999001', '42',  '3',  '14', '2',  '600',  CURRENT_TIMESTAMP(), 'demo_presentacion'),
    -- Partida 99999002 (Apex Legends)
    ('99999002', '100', '15', '5',  '8',  '2200', CURRENT_TIMESTAMP(), 'demo_presentacion'),
    ('99999002', '250', '6',  '10', '4',  '1100', CURRENT_TIMESTAMP(), 'demo_presentacion'),
    -- Partida 99999003 (Rocket League)
    ('99999003', '1',   '4',  '2',  '6',  '1500', CURRENT_TIMESTAMP(), 'demo_presentacion'),
    ('99999003', '15',  '2',  '5',  '3',  '900',  CURRENT_TIMESTAMP(), 'demo_presentacion');

-- 4.3 Confirmar que entraron en Bronze
SELECT 
    (SELECT COUNT(*) FROM PRO_BRONZE_DB_STEAM.KAGGLE.MATCH_RAW 
     WHERE _SOURCE_FILE = 'demo_presentacion') AS partidas_nuevas_bronze,
    (SELECT COUNT(*) FROM PRO_BRONZE_DB_STEAM.KAGGLE.MATCH_PLAYER_RAW 
     WHERE _SOURCE_FILE = 'demo_presentacion') AS stats_nuevas_bronze;
-- Deberías ver: partidas_nuevas_bronze = 3, stats_nuevas_bronze = 8.


-- ════════════════════════════════════════════════════════════════════════════
--   EJECUTA EN DBT:
--
--   dbt run --select stg_kaggle__match+ stg_kaggle__match_player+
--
--   En el log, fíjate en el número que aparece junto a "SUCCESS" en
--   fct_match_player — esas son las filas que ha procesado el incremental.
--   No serán 400.000, serán solo las 8 nuevas.
--
--   Cuando termine en verde, vuelve aquí y ejecuta el bloque 5.
-- ════════════════════════════════════════════════════════════════════════════


-- ============================================================================
-- 5. VERIFICACIÓN FINAL EN GOLD
-- ============================================================================

-- 5.1 Estado actual: deberías ver 8 filas más que el "antes"
SELECT 
    COUNT(*) AS total_filas_gold,
    MAX(_LOADED_AT) AS ultima_carga_madrid
FROM PRO_GOLD_DB_STEAM.MARTS.FCT_MATCH_PLAYER;
-- Compara con el "antes" del bloque 3 — debe haber 8 filas más
-- y la última carga debe ser de hace unos segundos.

-- 5.2 Las 8 filas nuevas en detalle (con sus KDA calculados)
SELECT 
    MATCH_ID,
    ID_JUGADOR,
    KILLS,
    DEATHS,
    ASSISTS,
    KDA,
    _LOADED_AT
FROM PRO_GOLD_DB_STEAM.MARTS.FCT_MATCH_PLAYER
WHERE MATCH_ID IN ('99999001', '99999002', '99999003')
ORDER BY MATCH_ID, KDA DESC;
-- Aquí ves las 8 estadísticas que has subido a través de todo el pipeline.

-- 5.3 (Opcional) Top 10 jugadores por KDA en SQL
SELECT
    j.nickname,
    SUM(f.kills)   AS total_kills,
    SUM(f.deaths)  AS total_deaths,
    SUM(f.assists) AS total_assists,
    ROUND(
        (SUM(f.kills) + SUM(f.assists)) / NULLIF(SUM(f.deaths), 0),
        2
    ) AS kda_acumulado
FROM PRO_GOLD_DB_STEAM.MARTS.FCT_MATCH_PLAYER f
JOIN PRO_GOLD_DB_STEAM.MARTS.DIM_JUGADOR j
    ON f.id_jugador = j.id_jugador
GROUP BY j.nickname
HAVING SUM(f.deaths) > 0
ORDER BY kda_acumulado DESC
LIMIT 10;
-- Después de mostrar esto, cambias a Power BI y enseñas el mismo ranking
-- pero ya visualizado en el dashboard.

-- ============================================================================
-- 6. MOSTRAR SNAPSHOT FUNCIONANDO EN PRODUCCION
-- ============================================================================

SELECT GAME, TOTAL_REVIEWS, DBT_VALID_FROM, DBT_VALID_TO, DBT_SCD_ID
FROM PRO_BRONZE_DB_STEAM.SNAPSHOTS.GAMES_RAW_SNAPSHOT
WHERE GAME = 'Dota 2'
LIMIT 3;

-- ============================================================================
-- 7. LIMPIEZA DESPUÉS DE LA DEMO (ejecutar después de la presentación)
-- ============================================================================
-- No ejecutes este bloque durante la demo. Es para dejar el sistema limpio
-- una vez terminada la presentación.

/*
DELETE FROM PRO_BRONZE_DB_STEAM.KAGGLE.MATCH_RAW
WHERE _SOURCE_FILE = 'demo_presentacion';

DELETE FROM PRO_BRONZE_DB_STEAM.KAGGLE.MATCH_PLAYER_RAW
WHERE _SOURCE_FILE = 'demo_presentacion';

DELETE FROM PRO_GOLD_DB_STEAM.MARTS.FCT_MATCH_PLAYER
WHERE MATCH_ID IN ('99999001', '99999002', '99999003');


SELECT * FROM PRO_BRONZE_DB_STEAM.SNAPSHOTS.games_raw_snapshot limit 5;
*/




SELECT DISTINCT 
    gm.nombre AS modalidad,
    COUNT(*) AS num_partidas
FROM PRO_GOLD_DB_STEAM.MARTS.FCT_MATCH_PLAYER f
JOIN PRO_GOLD_DB_STEAM.MARTS.DIM_JUEGO j 
    ON f.id_juego = j.id_juego
JOIN PRO_GOLD_DB_STEAM.MARTS.DIM_GAMEMODE gm 
    ON f.id_gamemode = gm.id_gamemode
WHERE j.nombre = 'Dota 2'
GROUP BY gm.nombre
ORDER BY num_partidas DESC;

SELECT 
    id_desarrollador,
    nombre,
    LENGTH(nombre) AS longitud,
    total_juegos
FROM PRO_GOLD_DB_STEAM.MARTS.DIM_DESARROLLADOR
ORDER BY total_juegos DESC
LIMIT 5;

-- Comparar juegos según id_desarrollador
SELECT 
    'En FCT_JUEGO' AS origen,
    COUNT(DISTINCT id_desarrollador) AS desarrolladores_distintos,
    COUNT(*) AS total_filas
FROM PRO_GOLD_DB_STEAM.MARTS.FCT_JUEGO
UNION ALL
SELECT 
    'En DIM_DESARROLLADOR',
    COUNT(DISTINCT id_desarrollador),
    COUNT(*)
FROM PRO_GOLD_DB_STEAM.MARTS.DIM_DESARROLLADOR;

-- Cuántos juegos huérfanos hay (fact sin pareja en dim)
SELECT COUNT(*) AS juegos_huerfanos
FROM PRO_GOLD_DB_STEAM.MARTS.FCT_JUEGO f
LEFT JOIN PRO_GOLD_DB_STEAM.MARTS.DIM_DESARROLLADOR d
    ON f.id_desarrollador = d.id_desarrollador
WHERE d.id_desarrollador IS NULL;

SELECT 
    COUNT(*) AS juegos_con_developer_null_en_intermediate
FROM PRO_SILVER_DB_STEAM.INTERMEDIATE.INT_GAMES__GAMES
WHERE id_developer IS NULL;
