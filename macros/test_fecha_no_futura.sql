{% test fecha_no_futura(model, column_name) %}

/*
  TEST GENÉRICO: fecha_no_futura
  Verifica que una columna de fecha no contiene fechas posteriores a hoy.
  Útil para fechas de lanzamiento, creación de perfil, fin de partida, etc.
  Una fecha futura indica un error de parseo o un dato corrupto.

  Uso en el .yml:
    columns:
      - name: release_date
        data_tests:
          - fecha_no_futura
*/

select *
from {{ model }}
where {{ column_name }} > current_date()

{% endtest %}
