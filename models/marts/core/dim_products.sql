-- ===========================================================================
-- dim_products.sql
-- ===========================================================================
-- CAPA: Marts/Core (Gold)
-- MATERIALIZACIÓN: table
--
-- OBJETIVO:
--   Dimensión de productos. Se enriquece con métricas operativas como el
--   nivel de stock y un indicador de "low_stock" para alertas.
-- ===========================================================================

with products as (

    select * from {{ ref('stg_sql_server_dbo__products') }}

),

final as (

    select
          product_id
        , product_name
        , unit_price_usd
        , inventory_units

        -- Indicador derivado para alertas de stock bajo.
        -- Umbral configurado vía variable de proyecto si quisiéramos
        -- parametrizarlo: {{ var('low_stock_threshold', 10) }}
        , case
            when inventory_units = 0 then 'out_of_stock'
            when inventory_units < 10 then 'low_stock'
            else 'in_stock'
          end                                              as stock_status

        , date_load
    from products

)

select * from final
