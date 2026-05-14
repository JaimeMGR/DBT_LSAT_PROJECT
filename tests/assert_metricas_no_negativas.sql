-- TEST SINGULAR: assert_metricas_no_negativas
-- Verifica que ninguna métrica de jugadores o reseñas tenga valores negativos
-- Los valores negativos son imposibles en el negocio y serían errores de carga

{{
    config(
        severity = 'warn'
    )
}}

SELECT
    id_steam,
    nombre_juego,
    'resenas_positivas'      AS columna_afectada,
    resenas_positivas::VARCHAR AS valor
FROM {{ ref('stg_kaggle__games') }}
WHERE resenas_positivas < 0

UNION ALL

SELECT id_steam, nombre_juego, 'resenas_negativas', resenas_negativas::VARCHAR
FROM {{ ref('stg_kaggle__games') }}
WHERE resenas_negativas < 0

UNION ALL

SELECT id_steam, nombre_juego, 'total_resenas', total_resenas::VARCHAR
FROM {{ ref('stg_kaggle__games') }}
WHERE total_resenas < 0

UNION ALL

SELECT id_steam, nombre_juego, 'pico_historico', pico_historico::VARCHAR
FROM {{ ref('stg_kaggle__games') }}
WHERE pico_historico < 0

UNION ALL

SELECT id_steam, nombre_juego, 'jugadores_actuales', jugadores_actuales::VARCHAR
FROM {{ ref('stg_kaggle__games') }}
WHERE jugadores_actuales < 0
