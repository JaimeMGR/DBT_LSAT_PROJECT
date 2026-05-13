-- ===========================================================================
-- stg_sql_server_dbo__addresses.sql
-- ===========================================================================
-- CAPA: Staging
-- ORIGEN: source('sql_server_dbo', 'addresses')
-- ===========================================================================

with src_addresses as (

    select *
    from {{ source('sql_server_dbo', 'addresses') }}
    where coalesce(_fivetran_deleted, false) = false

),

renamed_casted as (

    select
          address_id
        , address                    as address_line
        , zipcode
        , state
        , country
        , _fivetran_synced           as date_load
    from src_addresses

)

select * from renamed_casted
