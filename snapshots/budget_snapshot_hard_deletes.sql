-- ===========================================================================
-- budget_snapshot_hard_deletes.sql
-- ===========================================================================
-- TIPO: Snapshot
-- ESTRATEGIA: timestamp + hard_deletes='new_record'
--
-- ¿QUÉ ES `hard_deletes` Y CUÁNDO USARLO?
--   Cuando el sistema origen BORRA físicamente registros (no soft-delete),
--   un snapshot estándar no se entera del borrado y la última versión queda
--   con `dbt_valid_to = NULL` (como si siguiera vigente).
--
--   Tres opciones:
--     - 'ignore':       comportamiento por defecto. dbt ignora los borrados.
--                       La última versión queda abierta indefinidamente.
--     - 'invalidate':   marca la última versión como inválida (rellena
--                       dbt_valid_to con la fecha actual). NO añade fila.
--     - 'new_record':   añade una nueva fila marcada como borrada
--                       (columna `dbt_is_deleted = TRUE`). Histórico
--                       completo del ciclo de vida del registro.
--
-- RECOMENDACIÓN:
--   - Usar 'new_record' cuando el negocio necesita auditoría completa
--     (¿cuándo se borró cada registro?).
--   - Usar 'invalidate' cuando solo nos importa "ya no está vigente".
--   - 'ignore' solo si el origen NUNCA borra registros (insert-only).
-- ===========================================================================

{% snapshot budget_snapshot_hard_deletes %}

    {{
        config(
          target_schema='snapshots',
          unique_key='_row',
          strategy='timestamp',
          updated_at='_fivetran_synced',
          hard_deletes='new_record'
        )
    }}

    select * from {{ source('google_sheets', 'budget') }}

{% endsnapshot %}
