{# ===========================================================================
   cents_to_dollars.sql
   ===========================================================================
   Macro de utilidad: convierte una columna en céntimos a dólares (división
   por 100 con redondeo a 2 decimales).

   Es un ejemplo simple para enseñar a los alumnos cómo encapsular lógica
   reutilizable. En proyectos reales podríais tener una librería interna de
   macros para conversiones de moneda, normalización de teléfonos, etc.

   USO en un modelo:
     select
         order_id
       , {{ cents_to_dollars('order_total_cents') }} as order_total_usd
     from raw_orders
   =========================================================================== #}

{% macro cents_to_dollars(column_name, scale=2) %}

    round(({{ column_name }} / 100), {{ scale }})

{% endmacro %}
