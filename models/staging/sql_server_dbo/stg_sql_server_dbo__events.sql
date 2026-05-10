-- ===========================================================================
-- stg_sql_server_dbo__events.sql
-- ===========================================================================
-- CAPA: Staging
-- ORIGEN: source('sql_server_dbo', 'events')
-- MATERIALIZACIÓN: view (heredada)
--
-- NOTA EDUCATIVA:
--   La tabla events suele ser muy voluminosa en la práctica. Un caso real
--   probablemente la materialice como `incremental` para evitar reprocesar
--   el histórico. Aquí dejamos la versión vista como base y los alumnos
--   pueden ver la versión incremental en stg_sql_server_dbo__events_incremental.sql
-- ===========================================================================

with src_events as (

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
