-- ===========================================================================
-- fct_orders.sql
-- ===========================================================================
-- CAPA: Marts/Core (Gold)
-- MATERIALIZACIÓN: table
--
-- OBJETIVO:
--   Tabla de hechos de pedidos. Granularidad: una fila por pedido.
--   Es la fuente de verdad para análisis de pedidos.
--
-- DEPENDENCIAS:
--   - int_orders__enriched (modelo intermedio que ya une orders+addresses+promos)
-- ===========================================================================

with orders_enriched as (

    select * from {{ ref('int_orders__enriched') }}

),

final as (

    select
          order_id
        , user_id
        , address_id                              -- FK a dim_addresses
        , promo_id

        -- Métricas (hechos)
        , item_order_cost_usd
        , shipping_cost_usd
        , discount_usd
        , total_order_cost_usd
        , total_order_cost_usd - discount_usd     as net_order_cost_usd

        -- Atributos descriptivos del evento
        , status_order
        , shipping_service
        , tracking_id

        -- Fechas
        , created_at_utc                          as order_created_at_utc
        , estimated_delivery_at_utc
        , delivered_at_utc
        , days_to_deliver

        , date_load
    from orders_enriched

)

select * from final
