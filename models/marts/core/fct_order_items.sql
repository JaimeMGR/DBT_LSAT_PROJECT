-- ===========================================================================
-- fct_order_items.sql
-- ===========================================================================
-- CAPA: Marts/Core (Gold)
-- MATERIALIZACIÓN: table
--
-- OBJETIVO:
--   Tabla de hechos a nivel de línea de pedido (granularidad fina).
--   Una fila por (order_id, product_id). Útil para análisis de productos
--   más vendidos, ingresos por producto, etc.
-- ===========================================================================

with order_items as (

    select * from {{ ref('stg_sql_server_dbo__order_items') }}

),

orders as (

    select * from {{ ref('stg_sql_server_dbo__orders') }}

),

products as (

    select * from {{ ref('stg_sql_server_dbo__products') }}

),

final as (

    select
          oi.order_item_id
        , oi.order_id                                       -- FK a fct_orders
        , oi.product_id                                     -- FK a dim_products
        , o.user_id                                         -- FK a dim_users (denormalizado para queries directas)
        , o.created_at_utc                                  as order_created_at_utc

        -- Métricas
        , oi.quantity                                       as quantity_units
        , p.unit_price_usd
        , oi.quantity * p.unit_price_usd                    as line_total_usd

        , oi.date_load
    from order_items oi
    inner join orders   o on oi.order_id   = o.order_id
    inner join products p on oi.product_id = p.product_id

)

select * from final
