{% macro obtener_segmento(columna_resenas) %}
{#
  MACRO: obtener_segmento
  Devuelve el nombre del segmento de un juego según el volumen de reseñas.
  Centraliza la lógica de negocio para que sea reutilizable en cualquier modelo.

  Segmentos:
    - Nicho:    0–100 reseñas
    - Pequeño:  101–1.000 reseñas
    - Medio:    1.001–10.000 reseñas
    - Grande:   10.001–100.000 reseñas
    - AAA:      > 100.000 reseñas

  Uso:
    {{ obtener_segmento('total_resenas') }}
#}
    CASE
        WHEN {{ columna_resenas }} IS NULL         THEN 'Sin clasificar'
        WHEN {{ columna_resenas }} <= 100          THEN 'Nicho'
        WHEN {{ columna_resenas }} <= 1000         THEN 'Pequeño'
        WHEN {{ columna_resenas }} <= 10000        THEN 'Medio'
        WHEN {{ columna_resenas }} <= 100000       THEN 'Grande'
        ELSE                                            'AAA'
    END
{% endmacro %}
