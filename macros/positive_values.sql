{# ===========================================================================
   positive_values.sql
   ===========================================================================
   TEST GENÉRICO custom: valida que los valores de una columna son > 0.

   USO en cualquier YAML:
     columns:
       - name: quantity
         data_tests:
           - positive_values

   El test FALLA si la query devuelve filas (es decir, si encuentra valores
   que NO son positivos). Por eso seleccionamos las filas que NO cumplen
   la condición.

   Los tests genéricos custom pueden vivir en /macros/ o en /tests/generic/.
   Los ponemos aquí en /macros/ porque dbt los detecta automáticamente sin
   necesidad de configuración adicional.
   =========================================================================== #}

{% test positive_values(model, column_name) %}

    select *
    from {{ model }}
    where {{ column_name }} <= 0

{% endtest %}
