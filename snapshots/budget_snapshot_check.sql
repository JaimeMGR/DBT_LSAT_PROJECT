-- ===========================================================================
-- budget_snapshot_check.sql
-- ===========================================================================
-- TIPO: Snapshot
-- ESTRATEGIA: check (cuando NO hay un campo fiable de updated_at).
--
-- ¿CÓMO FUNCIONA?
--   En cada ejecución, dbt compara el valor actual de las columnas listadas
--   en `check_cols` con la última versión guardada. Si alguna ha cambiado,
--   crea una nueva versión.
--
-- CONTRA: más costoso de calcular que timestamp (requiere comparación columna
-- a columna). PRO: no depende de un campo de actualización.
--
-- ⚠️ IMPORTANTE: NO usar check_cols='all' en tablas grandes — degrada
-- rendimiento y dispara cambios por columnas que no os importan (timestamps
-- de carga de Fivetran, por ejemplo). Listad SIEMPRE las columnas relevantes.
-- ===========================================================================

{% snapshot budget_snapshot_check %}

    {{
        config(
          target_schema='snapshots',
          unique_key='_row',
          strategy='check',
          check_cols=['quantity', 'month', 'product_id']
        )
    }}

    select * from {{ source('google_sheets', 'budget') }}

{% endsnapshot %}
