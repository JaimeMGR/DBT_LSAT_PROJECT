{{
    config(
        materialized = 'table'
    )
}}

/*
  MODELO: dim_segmento
  CAPA:   Marts / Dimensions (Gold)
  DESCRIPCIÓN: Segmentación de juegos por volumen de reseñas y jugadores.
               Se define como seed (tabla estática) pero se materializa aquí
               para poder hacer JOIN en la tabla de hechos.

  Segmentos basados en total_resenas:
    - Nicho:     0–100 reseñas
    - Pequeño:   101–1.000 reseñas
    - Medio:     1.001–10.000 reseñas
    - Grande:    10.001–100.000 reseñas
    - AAA:       > 100.000 reseñas
*/

SELECT
    1 AS id_segmento, 'Nicho'    AS nombre,
    '0 - 100'         AS rango_resenas,
    'Muy pocos jugadores y reseñas' AS descripcion
UNION ALL SELECT 2, 'Pequeño',  '101 - 1.000',      'Audiencia pequeña pero establecida'
UNION ALL SELECT 3, 'Medio',    '1.001 - 10.000',   'Juego con comunidad activa'
UNION ALL SELECT 4, 'Grande',   '10.001 - 100.000', 'Título popular'
UNION ALL SELECT 5, 'AAA',      '> 100.000',        'Blockbuster con gran comunidad'
