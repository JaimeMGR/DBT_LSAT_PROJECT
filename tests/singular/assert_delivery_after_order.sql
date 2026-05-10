-- ===========================================================================
-- assert_delivery_after_order.sql
-- ===========================================================================
-- TIPO: Test singular
--
-- ¿QUÉ ES UN TEST SINGULAR?
--   Una sentencia SQL que VALIDA una regla de negocio específica. dbt la
--   ejecuta y considera que el test FALLA si devuelve alguna fila.
--
--   Filosofía: "muéstrame las filas que rompen la regla". Si no hay
--   ninguna, el test pasa.
--
-- REGLA DE NEGOCIO QUE VALIDAMOS:
--   La fecha de entrega NUNCA puede ser anterior a la fecha de creación
--   del pedido. Si lo es, hay corrupción de datos en el origen y debemos
--   alertar.
--
-- COMANDO:
--   dbt test --select assert_delivery_after_order
-- ===========================================================================

select
      order_id
    , order_created_at_utc
    , delivered_at_utc
    , datediff('day', order_created_at_utc, delivered_at_utc) as days_diff
from {{ ref('fct_orders') }}
where delivered_at_utc is not null
  and delivered_at_utc < order_created_at_utc
