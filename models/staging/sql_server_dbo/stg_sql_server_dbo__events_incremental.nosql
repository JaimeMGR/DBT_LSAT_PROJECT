-- ===========================================================================
-- stg_sql_server_dbo__events_incremental.sql
-- ===========================================================================
-- CAPA: Staging
-- ORIGEN: source('sql_server_dbo', 'events')
-- MATERIALIZACIÓN: incremental
--
-- OBJETIVO EDUCATIVO:
--   Mostrar el patrón clásico de modelo incremental con `is_incremental()`.
--   En la práctica este patrón es lo que más usaréis para tablas con
--   alto volumen y datos que llegan de forma append-only o append-mostly.
--
-- CONFIGURACIÓN:
--   - materialized='incremental'  → dbt mantiene la tabla y solo añade nuevos
--   - unique_key='event_id'       → en caso de match con una fila existente,
--                                   hace MERGE (update) en lugar de duplicar
--   - on_schema_change='fail'     → si añadimos/quitamos columnas en el SQL,
--                                   dbt fallará en vez de silenciar el error.
--                                   Otras opciones: append_new_columns, sync_all_columns
--
-- COMANDOS ÚTILES:
--   dbt run --select stg_sql_server_dbo__events_incremental
--   dbt run --select stg_sql_server_dbo__events_incremental --full-refresh
-- ===========================================================================

{{ config(
    materialized='incremental',
    unique_key='event_id',
    on_schema_change='fail'
) }}

with src_events as (

    select *
    from {{ source('sql_server_dbo', 'events') }}
    where coalesce(_fivetran_deleted, false) = false

    {% if is_incremental() %}
        -- En ejecuciones incrementales (no full-refresh ni primera carga),
        -- solo procesamos las filas con timestamp más reciente que el máximo
        -- ya cargado en la tabla destino.
        --
        -- `{{ this }}` referencia esta misma tabla (auto-referencia).
        --
        -- Restamos un margen pequeño para capturar registros que pudieran
        -- llegar con cierto retraso (late-arriving data).
        and _fivetran_synced > (
            select coalesce(max(_fivetran_synced), '1900-01-01'::timestamp_tz)
                 - interval '1 hour'
            from {{ this }}
        )
    {% endif %}

),

renamed_casted as (

    select
          event_id
        , session_id
        , user_id
        , page_url
        , event_type
        , order_id
        , product_id
        , created_at                 as created_at_utc
        , _fivetran_synced           as date_load
    from src_events

)

select * from renamed_casted
