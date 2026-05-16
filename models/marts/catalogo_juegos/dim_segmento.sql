{{ config(materialized = 'table') }}

/*
  DIMENSIÓN: dim_segmento
  MART:      Catálogo de juegos
  ORIGEN:    seed_segmentos.csv

  Dimensión estática de segmentación de juegos por volumen de reseñas.
  Se alimenta de un seed CSV versionado en el repositorio.
*/

SELECT
    id_segmento,
    nombre,
    rango_resenas,
    descripcion
FROM {{ ref('seed_segmentos') }}
