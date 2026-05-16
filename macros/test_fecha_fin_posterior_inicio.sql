{% test fecha_fin_posterior_inicio(model, column_name, fecha_inicio, fecha_fin) %}

/*
  TEST GENÉRICO: fecha_fin_posterior_inicio
  Verifica que una fecha de fin es siempre posterior o igual a la de inicio.
  Útil para partidas (day_started / day_ended).

  Nota: dbt pasa automáticamente 'column_name' (la columna sobre la que se
  aplica el test). No lo usamos aquí pero debe estar en la firma del macro.

  Uso en el .yml:
    columns:
      - name: day_ended
        data_tests:
          - fecha_fin_posterior_inicio:
              fecha_inicio: day_started
              fecha_fin: day_ended
*/

SELECT *
FROM {{ model }}
WHERE {{ fecha_fin }} < {{ fecha_inicio }}

{% endtest %}
