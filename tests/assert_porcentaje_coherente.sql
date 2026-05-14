-- TEST SINGULAR: assert_porcentaje_coherente
-- Verifica que el porcentaje_positivo calculado manualmente
-- está alineado con el campo porcentaje_positivo del origen.
-- Diferencia tolerada: 2 puntos porcentuales (redondeo del origen)

SELECT
    id_steam,
    nombre_juego,
    resenas_positivas,
    total_resenas,
    porcentaje_positivo                                                     AS porcentaje_origen,
    ROUND(resenas_positivas / NULLIF(total_resenas, 0) * 100, 2)           AS porcentaje_calculado,
    ABS(
        porcentaje_positivo
        - ROUND(resenas_positivas / NULLIF(total_resenas, 0) * 100, 2)
    )                                                                       AS diferencia
FROM {{ ref('stg_kaggle__games') }}
WHERE resenas_positivas IS NOT NULL
  AND total_resenas IS NOT NULL
  AND total_resenas > 0
  AND porcentaje_positivo IS NOT NULL
  AND ABS(
        porcentaje_positivo
        - ROUND(resenas_positivas / NULLIF(total_resenas, 0) * 100, 2)
      ) > 2
