{% macro parsear_fecha(columna) %}
{#
  MACRO: parsear_fecha
  Intenta parsear una columna VARCHAR que puede contener fechas
  en múltiples formatos sucios. Devuelve el primer formato que funcione,
  o NULL si ninguno coincide.

  Formatos soportados (en orden de prioridad):
    1. YYYY-MM-DD  (formato canónico ISO)
    2. DD/MM/YYYY
    3. MM-DD-YYYY
    4. DD-MM-YY
    5. DD-MM-YYYY

  Uso:
    {{ parsear_fecha('release') }}
    {{ parsear_fecha('all_time_peak_date') }}
#}
    COALESCE(
        TRY_TO_DATE({{ columna }}, 'YYYY-MM-DD'),
        TRY_TO_DATE({{ columna }}, 'DD/MM/YYYY'),
        TRY_TO_DATE({{ columna }}, 'MM-DD-YYYY'),
        TRY_TO_DATE({{ columna }}, 'DD-MM-YY'),
        TRY_TO_DATE({{ columna }}, 'DD-MM-YYYY')
    )
{% endmacro %}
