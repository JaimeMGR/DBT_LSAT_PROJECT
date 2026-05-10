-- ===========================================================================
-- assert_orders_match_order_items.sql
-- ===========================================================================
-- TIPO: Test singular (cross-model)
--
-- REGLA DE NEGOCIO:
--   Todo pedido en fct_orders debe tener al menos una línea en
--   fct_order_items. Si no, hay un pedido "fantasma" sin productos.
--
-- ⚠️ Este test puede tardar en tablas muy grandes; en producción quizá
-- quieras moverlo a un job nocturno y no al CI.
-- ===========================================================================

select
      o.order_id
    , o.user_id
    , o.order_created_at_utc
from {{ ref('fct_orders') }} o
left join {{ ref('fct_order_items') }} oi
    on o.order_id = oi.order_id
where oi.order_id is null
