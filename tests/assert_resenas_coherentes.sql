-- TEST SINGULAR: assert_resenas_coherentes
-- Verifica que total_resenas = resenas_positivas + resenas_negativas
-- Si devuelve filas, el test FALLA (hay inconsistencia en los datos)

{{
    config(
        severity = 'warn'
    )
}}

SELECT
    id_steam,
    nombre_juego,
    resenas_positivas,
    resenas_negativas,
    total_resenas,
    (resenas_positivas + resenas_negativas)  AS total_calculado,
    ABS(total_resenas - (resenas_positivas + resenas_negativas)) AS diferencia
FROM {{ ref('stg_kaggle__games') }}
WHERE resenas_positivas IS NOT NULL
  AND resenas_negativas IS NOT NULL
  AND total_resenas IS NOT NULL
  -- Tolerancia de 1 unidad por posibles redondeos del origen
  AND ABS(total_resenas - (resenas_positivas + resenas_negativas)) > 1
