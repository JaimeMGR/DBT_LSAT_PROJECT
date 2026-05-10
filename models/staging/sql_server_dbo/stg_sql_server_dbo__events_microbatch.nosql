-- ===========================================================================
-- stg_sql_server_dbo__events_microbatch.sql
-- ===========================================================================
-- CAPA: Staging
-- ORIGEN: source('sql_server_dbo', 'events')
-- MATERIALIZACIÓN: incremental con estrategia 'microbatch'
--
-- OBJETIVO EDUCATIVO:
--   Mostrar la estrategia microbatch (dbt 1.9+ y Versionless), que es la
--   evolución del patrón incremental clásico para series temporales.
--
-- DIFERENCIAS CON EL INCREMENTAL CLÁSICO:
--   - NO usamos `is_incremental()` ni filtros manuales con `{{ this }}`
--   - Cada batch (definido por batch_size) es atómico e idempotente:
--     dbt borra y reinserta los datos de ese batch — orden y reprocesos seguros
--   - `lookback` permite reprocesar N batches hacia atrás automáticamente
--   - Para reprocesar un rango: dbt run --event-time-start ... --event-time-end ...
--
-- REQUISITOS:
--   1. El source debe declarar `event_time` en su YAML.
--   2. dbt 1.9+ (o Versionless) y la flag DBT_EXPERIMENTAL_MICROBATCH=true
--      en versiones beta.
-- ===========================================================================

{{ config(
    materialized='incremental',
    incremental_strategy='microbatch',
    event_time='created_at_utc',
    begin='2024-01-01',
    batch_size='day',
    lookback=2
) }}

with src_events as (

    -- IMPORTANTE: en microbatch dbt aplica automáticamente el filtro temporal
    -- sobre los upstreams. No hay que escribir el WHERE manualmente.
    select *
    from {{ source('sql_server_dbo', 'events') }}
    where coalesce(_fivetran_deleted, false) = false

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
