{# ===========================================================================
   _core__docs.md — Bloques de documentación reutilizables
   ===========================================================================
   Estos bloques se invocan desde los YAML con la sintaxis:
       description: '{{ doc("nombre_del_bloque") }}'

   Ventajas vs descripciones inline:
     1. Reutilización: un bloque sirve para varios modelos.
     2. Mantenibilidad: cambiar la definición en un sitio actualiza todos.
     3. Soporte de Markdown completo (tablas, listas, código, links).
   =========================================================================== #}



{% docs st_stock_status %}

Estado del stock del producto. Categorización derivada del campo
`inventory_units`:

| stock_status   | regla                       |
|----------------|-----------------------------|
| out_of_stock   | inventory_units = 0         |
| low_stock      | 0 < inventory_units < 10    |
| in_stock       | inventory_units >= 10       |

Esta categorización se usa para alertas operativas y para mostrar avisos
de stock al equipo de Operaciones.

{% enddocs %}

