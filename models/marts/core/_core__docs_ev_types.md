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




{% docs ev_event_type %}

Tipo de evento generado por el usuario en la plataforma. Valores posibles:

| event_type        | descripción                                            |
|-------------------|--------------------------------------------------------|
| page_view         | El usuario ha visitado una página                       |
| add_to_cart       | El usuario ha añadido un producto al carrito           |
| checkout          | El usuario ha finalizado un pedido                     |
| package_shipped   | El sistema ha registrado el envío del pedido           |

Los eventos `checkout` y `package_shipped` siempre llevan asociado un
`order_id`. Los eventos `add_to_cart` siempre llevan asociado un
`product_id`.

{% enddocs %}
