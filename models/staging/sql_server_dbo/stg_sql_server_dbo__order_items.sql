-- ===========================================================================
-- stg_sql_server_dbo__order_items.sql
-- ===========================================================================
-- CAPA: Staging
-- ORIGEN: source('sql_server_dbo', 'order_items')
-- NOTA: La granularidad es (order_id, product_id) → no hay PK natural única
--       en una sola columna. Generamos una surrogate key con dbt_utils para
--       facilitar tests de unicidad downstream.
-- ===========================================================================

with src_order_items as (

    select *
    from {{ source('sql_server_dbo', 'order_items') }}
    where coalesce(_fivetran_deleted, false) = false

),

renamed_casted as (

    select
          -- Surrogate key compuesta — útil para tests de unique downstream
          {{ dbt_utils.generate_surrogate_key(['order_id', 'product_id']) }} as order_item_id
        , order_id
        , product_id
        , quantity
        , _fivetran_synced                    as date_load
    from src_order_items

)

select * from renamed_casted
