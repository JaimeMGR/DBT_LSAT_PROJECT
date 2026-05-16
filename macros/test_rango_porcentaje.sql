{% test rango_porcentaje(model, column_name) %}

/*
  TEST GENÉRICO: rango_porcentaje
  Verifica que una columna numérica que representa un porcentaje
  está dentro del rango válido 0-100.

  Uso en el .yml:
    columns:
      - name: review_percentage
        data_tests:
          - rango_porcentaje
*/

SELECT *
FROM {{ model }}
WHERE {{ column_name }} < 0
   OR {{ column_name }} > 100

{% endtest %}
