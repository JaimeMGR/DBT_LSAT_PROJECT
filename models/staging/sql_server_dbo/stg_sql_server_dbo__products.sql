-- ===========================================================================
-- stg_sql_server_dbo__products.sql
-- ===========================================================================
-- CAPA: Staging
-- ORIGEN: source('sql_server_dbo', 'products')
-- ===========================================================================

with src_products as (

    select *
    from {{ source('sql_server_dbo', 'products') }}
    where coalesce(_fivetran_deleted, false) = false

),

renamed_casted as (

    select
          product_id
        , name                       as product_name
        , price                      as unit_price_usd
        , inventory                  as inventory_units
        , _fivetran_synced           as date_load
    from src_products

)

select * from renamed_casted
