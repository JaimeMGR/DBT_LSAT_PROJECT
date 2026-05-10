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


{% docs or_order_status %}

Estado del pedido. Valores posibles:

| status     | definición                                            |
|------------|-------------------------------------------------------|
| preparing  | Pedido recibido y en preparación                      |
| shipped    | Pedido enviado, no entregado todavía                  |
| delivered  | Pedido entregado al cliente                           |

{% enddocs %}
