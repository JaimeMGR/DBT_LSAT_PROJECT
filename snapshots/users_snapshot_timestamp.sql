-- ===========================================================================
-- users_snapshot_timestamp.sql
-- ===========================================================================
-- TIPO: Snapshot del ejercicio práctico del módulo 12 del curso
-- ESTRATEGIA: timestamp
--
-- CASO DE USO REAL:
--   Trackear cambios en los datos de los usuarios. Si un usuario cambia su
--   email, dirección o teléfono, queremos:
--     - Saber cuándo cambió (auditoría legal: GDPR, SOX, ...)
--     - Conservar el valor anterior para resolución de incidencias
--     - Asociar pedidos antiguos con el email VIGENTE en el momento del pedido
--
-- COMANDO:
--   dbt snapshot --select users_snapshot_timestamp
-- ===========================================================================

{% snapshot users_snapshot_timestamp %}

    {{
        config(
          target_schema='snapshots',
          unique_key='user_id',
          strategy='timestamp',
          updated_at='updated_at',          
          hard_deletes='new_record'         
        )
    }}

    select
          user_id
        , first_name
        , last_name
        , email
        , phone_number
        , address_id
        , created_at
        , updated_at
    from {{ source('sql_server_dbo', 'users') }}

{% endsnapshot %}
