-- ===========================================================================
-- budget_snapshot_timestamp.sql
-- ===========================================================================
-- TIPO: Snapshot
-- ESTRATEGIA: timestamp (la RECOMENDADA cuando el origen tiene un campo
--             fiable de "última actualización").
--
-- DESTINO: <ALUMNO>_DEV_SILVER_DB.snapshots.budget_snapshot_timestamp
--
-- COMANDO PARA EJECUTAR:
--   dbt snapshot --select budget_snapshot_timestamp
--
-- ¿QUÉ GENERA dbt EN CADA EJECUCIÓN?
--   - Primera ejecución: crea la tabla con todas las filas + 4 columnas
--     extra (dbt_scd_id, dbt_updated_at, dbt_valid_from, dbt_valid_to).
--   - Ejecuciones posteriores: si `_fivetran_synced` de un registro es
--     más reciente que la versión guardada, invalida la versión anterior
--     (pone dbt_valid_to) e inserta una nueva versión.
--
-- CASO DE USO TÍPICO:
--   Trazabilidad de cambios en tablas mutables: precio de productos,
--   estado de pedidos, datos de clientes, ...
-- ===========================================================================

{% snapshot budget_snapshot_timestamp %}

    {{
        config(
          target_schema='snapshots',
          unique_key='_row',
          strategy='timestamp',
          updated_at='_fivetran_synced'
        )
    }}

    select * from {{ source('google_sheets', 'budget') }}

{% endsnapshot %}
