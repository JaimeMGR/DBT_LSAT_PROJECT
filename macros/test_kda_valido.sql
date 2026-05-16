{% test kda_valido(model, column_name, kills_column, deaths_column, assists_column) %}

/*
  TEST GENÉRICO: kda_valido
  Verifica que las estadísticas KDA de una partida son valores válidos:
  no negativos y dentro de un rango razonable (un jugador no puede tener
  más de 100 kills/deaths/assists en una sola partida).

  Nota: dbt pasa automáticamente 'column_name' (la columna sobre la que se
  aplica el test). No lo usamos aquí pero debe estar en la firma del macro.

  Uso en el .yml:
    columns:
      - name: kills
        data_tests:
          - kda_valido:
              kills_column: kills
              deaths_column: deaths
              assists_column: assists
*/

SELECT *
FROM {{ model }}
WHERE {{ kills_column }}   < 0 OR {{ kills_column }}   > 100
   OR {{ deaths_column }}  < 0 OR {{ deaths_column }}  > 100
   OR {{ assists_column }} < 0 OR {{ assists_column }} > 100

{% endtest %}
