-- ===========================================================================
-- int_orders__enriched.sql
-- ===========================================================================
-- CAPA: Intermediate (marts/core/intermediate)
-- MATERIALIZACIÓN: view (heredada del dbt_project.yml)
--
-- OBJETIVO:
--   Combina pedidos con su address de envío y promo aplicada para tener un
--   dataset enriquecido reutilizable por múltiples marts downstream.
--
-- CUÁNDO USAR INTERMEDIATE:
--   - Cuando varios modelos finales (dim/fct) necesitan el mismo cálculo.
--   - Para evitar duplicar lógica de joins/agregaciones.
--   - Para centralizar transformaciones complejas y testarlas en un solo
--     punto.
-- ===========================================================================

with orders as (

    select * from {{ ref('stg_sql_server_dbo__orders') }}

),

addresses as (

    select * from {{ ref('stg_sql_server_dbo__addresses') }}

),

promos as (

    select * from {{ ref('stg_sql_server_dbo__promos') }}

),

joined as (

    select
          o.order_id
        , o.user_id
        , o.address_id
        , a.address_line
        , a.zipcode
        , a.state
        , a.country
        , o.promo_id
        , coalesce(p.discount_usd, 0)            as discount_usd
        , coalesce(p.status_promo, 'no_promo')   as status_promo
        , o.created_at_utc
        , o.estimated_delivery_at_utc
        , o.delivered_at_utc
        , o.tracking_id
        , o.shipping_service
        , o.shipping_cost_usd
        , o.item_order_cost_usd
        , o.total_order_cost_usd
        , o.status_order
        , o.date_load
        -- Métrica calculada: días desde la creación hasta la entrega.
        -- NULL si el pedido aún no se ha entregado.
        , datediff('day', o.created_at_utc, o.delivered_at_utc) as days_to_deliver
    from orders o
    left join addresses a on o.address_id = a.address_id
    left join promos    p on o.promo_id   = p.promo_id

)

select * from joined
