-- ===========================================================================
-- fct_events.sql
-- ===========================================================================
-- CAPA: Marts/Core (Gold)
-- MATERIALIZACIÓN: table
--
-- OBJETIVO:
--   Tabla de hechos de eventos. Una fila por evento. Es la base para análisis
--   de comportamiento de los usuarios en la plataforma.
-- ===========================================================================

with events as (

    select * from {{ ref('stg_sql_server_dbo__events') }}

),

final as (

    select
          event_id
        , session_id
        , user_id                                 -- FK a dim_users
        , product_id                              -- FK a dim_products (puede ser nulo)
        , order_id                                -- FK a fct_orders (puede ser nulo)
        , event_type
        , page_url
        , created_at_utc                          as event_at_utc
        , date_load
    from events

)

select * from final
