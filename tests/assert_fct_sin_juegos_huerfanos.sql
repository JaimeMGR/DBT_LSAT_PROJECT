-- TEST SINGULAR: assert_fct_sin_juegos_huerfanos
-- Verifica que todos los id_juego de la tabla de hechos
-- existen en dim_juego. Si hay huérfanos, hay un problema en el pipeline.

SELECT
    f.id_juego
FROM {{ ref('fct_actividad_juego') }} f
LEFT JOIN {{ ref('dim_juego') }} d
       ON f.id_juego = d.id_juego
WHERE d.id_juego IS NULL
