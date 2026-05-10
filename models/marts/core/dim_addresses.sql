-- ===========================================================================
-- dim_addresses.sql
-- ===========================================================================
-- CAPA: Marts/Core (Gold)
-- ===========================================================================

with addresses as (

    select * from {{ ref('stg_sql_server_dbo__addresses') }}

),

final as (

    select
          address_id
        , address_line
        , zipcode
        , state
        , country
        , date_load
    from addresses

)

select * from final
