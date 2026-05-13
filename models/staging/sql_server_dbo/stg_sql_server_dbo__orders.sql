-- ===========================================================================
-- stg_sql_server_dbo__orders.sql
-- ===========================================================================
-- CAPA: Staging
-- ORIGEN: source('sql_server_dbo', 'orders')
-- ===========================================================================

with src_orders as (

    select *
    from {{ source('sql_server_dbo', 'orders') }}
    where coalesce(_fivetran_deleted, false) = false

),

renamed_casted as (

    select
          order_id
        , user_id
        , address_id
        , promo_id
        , created_at                          as created_at_utc
        , estimated_delivery_at               as estimated_delivery_at_utc
        , delivered_at                        as delivered_at_utc
        , tracking_id
        , shipping_service
        , shipping_cost                       as shipping_cost_usd
        , order_cost                          as item_order_cost_usd
        , order_total                         as total_order_cost_usd
        , status                              as status_order
        , _fivetran_synced                    as date_load
    from src_orders

)

select * from renamed_casted
