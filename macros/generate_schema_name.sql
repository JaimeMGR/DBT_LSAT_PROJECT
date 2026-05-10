{# ===========================================================================
   generate_schema_name.sql
   ===========================================================================
   Macro built-in de dbt que controla cómo se generan los nombres de schema.
   Se ejecuta automáticamente para todos los modelos/seeds/snapshots.

   COMPORTAMIENTO POR DEFECTO de dbt:
     - Si NO hay custom_schema_name → usa target.schema (tu profile dev:
       suele ser `dbt_<usuario>`).
     - Si HAY custom_schema_name → usa `<target.schema>_<custom_schema_name>`,
       es decir prefija con tu schema personal.

   PROBLEMA con ese default:
     En entorno de PRO no queremos prefijos de desarrollador. Queremos que
     `core` se llame `core` literalmente, no `dbt_<user>_core`.

   SOLUCIÓN (este macro):
     - En entornos productivos (CI_CD, PRO, ...) → usar el custom_schema_name
       tal cual ('core', 'staging', 'snapshots', ...).
     - En entorno de desarrollo personal → usar el default schema del
       profile (sin prefijo) para no contaminar otros schemas.

   La variable env_var('DBT_ENVIRONMENTS') es la que diferencia entornos
   y se configura tanto a nivel de proyecto en dbt Cloud como en cada
   credencial de desarrollador (suele ser <ALUMNOX>_DEV en dev y _PRO en pro).
   =========================================================================== #}

{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- set default_schema = target.schema -%}

    {#- En entorno productivo o CI/CD usamos el custom_schema_name tal cual -#}
    {%- if env_var('DBT_ENVIRONMENTS', 'FAIL') in ['PRO', 'CI_CD']
            or custom_schema_name is not none -%}

        {{ custom_schema_name | trim }}

    {%- else -%}

        {{ default_schema }}

    {%- endif -%}

{%- endmacro %}
