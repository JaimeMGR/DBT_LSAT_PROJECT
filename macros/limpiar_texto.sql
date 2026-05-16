{% macro limpiar_texto(columna, mayusculas=false) %}
{#
  MACRO: limpiar_texto
  Limpia un campo de texto aplicando TRIM y opcionalmente normalizando
  a UPPER o LOWER. Convierte nulos disfrazados a NULL real.

  Parámetros:
    - columna    : nombre del campo a limpiar
    - mayusculas : si TRUE aplica UPPER, si FALSE aplica LOWER (default FALSE)

  Uso:
    {{ limpiar_texto('publisher') }}
    {{ limpiar_texto('primary_genre', mayusculas=true) }}
#}
    NULLIF(
        {% if mayusculas %}
            UPPER(TRIM({{ columna }}))
        {% else %}
            TRIM({{ columna }})
        {% endif %}
        , ''
    )
{% endmacro %}
