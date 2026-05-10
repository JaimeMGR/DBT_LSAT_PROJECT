-- ===========================================================================
-- fct_user_purchases.sql
-- ===========================================================================
-- CAPA: Marts/Marketing (Gold)
-- MATERIALIZACIÓN: table
--
-- OBJETIVO (Ejercicio 19.2 — Caso de uso del equipo de Marketing):
--   El equipo de marketing necesita conocer para cada usuario:
--     - Toda la información disponible del usuario
--     - Número de pedidos totales realizados
--     - Total gastado
--     - Total de gastos de envío
--     - Descuento total aplicado
--     - Total de productos comprados (suma de unidades)
--     - Total de productos diferentes comprados (cardinalidad)
--
-- ESTRATEGIA:
--   Agregamos por user_id desde fct_orders y fct_order_items, y enriquecemos
--   con los atributos de dim_users.
-- ===========================================================================

with users as (

    select * from {{ ref('dim_users') }}

),

orders as (

    select * from {{ ref('fct_orders') }}

),

order_items as (

    select * from {{ ref('fct_order_items') }}

),

-- ---------------------------------------------------------------------------
-- Métricas agregadas a nivel de pedido
-- ---------------------------------------------------------------------------
order_metrics as (

    select
          user_id
        , count(distinct order_id)              as total_orders
        , sum(total_order_cost_usd)             as total_spent_usd
        , sum(shipping_cost_usd)                as total_shipping_cost_usd
        , sum(discount_usd)                     as total_discount_usd
        , sum(net_order_cost_usd)               as total_net_spent_usd
        , min(order_created_at_utc)             as first_order_at_utc
        , max(order_created_at_utc)             as last_order_at_utc
    from orders
    group by user_id

),

-- ---------------------------------------------------------------------------
-- Métricas agregadas a nivel de línea (productos)
-- ---------------------------------------------------------------------------
product_metrics as (

    select
          user_id
        , sum(quantity_units)                   as total_products_bought
        , count(distinct product_id)            as total_distinct_products
    from order_items
    group by user_id

),

-- ---------------------------------------------------------------------------
-- Cruce final con la dimensión de usuarios
-- ---------------------------------------------------------------------------
final as (

    select
          u.user_id

        -- Atributos del usuario
        , u.first_name
        , u.last_name
        , u.full_name
        , u.email
        , u.is_valid_email_address
        , u.phone_number
        , u.address_line                        as user_address
        , u.zipcode                             as user_zipcode
        , u.state                               as user_state
        , u.country                             as user_country
        , u.registered_at_utc
        , u.days_since_registration

        -- Métricas de pedidos. coalesce a 0 para usuarios sin compras
        -- (no queremos NULL: facilita filtrado en BI).
        , coalesce(om.total_orders, 0)             as total_orders
        , coalesce(om.total_spent_usd, 0)          as total_spent_usd
        , coalesce(om.total_shipping_cost_usd, 0)  as total_shipping_cost_usd
        , coalesce(om.total_discount_usd, 0)       as total_discount_usd
        , coalesce(om.total_net_spent_usd, 0)      as total_net_spent_usd

        -- Métricas de productos
        , coalesce(pm.total_products_bought, 0)    as total_products_bought
        , coalesce(pm.total_distinct_products, 0)  as total_distinct_products

        -- Fechas relevantes
        , om.first_order_at_utc
        , om.last_order_at_utc

        -- Segmentación derivada útil para campañas
        , case
            when om.total_orders is null      then 'never_bought'
            when om.total_orders = 1          then 'one_purchase'
            when om.total_orders = 2          then 'two_purchases'
            when om.total_orders >= 3         then 'three_or_more'
          end                                       as purchase_segment

    from users u
    left join order_metrics   om on u.user_id = om.user_id
    left join product_metrics pm on u.user_id = pm.user_id

)

select * from final
