-- ===========================================================================
-- stg_sql_server_dbo__promos.sql
-- ===========================================================================
-- CAPA: Staging
-- ORIGEN: source('sql_server_dbo', 'promos')
-- ===========================================================================

with src_promos as (

    select *
    from {{ source('sql_server_dbo', 'promos') }}
    where coalesce(_fivetran_deleted, false) = false

),

renamed_casted as (

    select
          promo_id
        , discount                   as discount_usd
        , status                     as status_promo
        , _fivetran_synced           as date_load
    from src_promos

)

select * from renamed_casted
