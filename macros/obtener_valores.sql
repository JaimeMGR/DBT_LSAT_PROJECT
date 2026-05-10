{# ===========================================================================
   obtener_valores.sql
   ===========================================================================
   Macro genérico que devuelve la lista de valores DISTINCT de una columna
   de una tabla/source. Útil para "pivots dinámicos": evitar hardcodear
   listas de tipos de evento, status, categorías, etc. dentro de los modelos.

   USO:
     {% set event_types = obtener_valores(ref('stg_events'), 'event_type') %}
     {%- for event_type in event_types %}
         sum(case when event_type = '{{ event_type }}' then 1 else 0 end)
             as {{ event_type }}_count
     {%- endfor %}

   ¿CUÁNDO se ejecuta la query interna?
     - SOLO en compile-time (no en runtime). dbt ejecuta la query
       SELECT DISTINCT durante la compilación del proyecto.
     - El bloque `{% if execute %}` evita que falle durante el `dbt parse`
       (cuando todavía no hay conexión disponible).

   ⚠️ LIMITACIÓN: para que esto funcione, la tabla referenciada DEBE
   existir en el DW antes de compilar. En la primera ejecución sobre un
   entorno limpio puede fallar. Workaround: ejecutar primero el modelo
   upstream (stg_events) y luego el que usa el macro.
   =========================================================================== #}

{% macro obtener_valores(table, column) %}

    {#- 1. Construimos la query SELECT DISTINCT a lanzar -#}
    {% set query_sql %}
        select distinct {{ column }}
        from {{ table }}
        where {{ column }} is not null
        order by {{ column }}
    {% endset %}

    {#- 2. La ejecutamos contra el DW. run_query devuelve un Agate Table -#}
    {% set results = run_query(query_sql) %}

    {#- 3. `execute` es TRUE solo en compile/run, FALSE durante parse.
           Esta guarda evita errores en el primer `dbt parse`. -#}
    {% if execute %}
        {% set results_list = results.columns[0].values() %}
    {% else %}
        {% set results_list = [] %}
    {% endif %}

    {{ return(results_list) }}

{% endmacro %}
