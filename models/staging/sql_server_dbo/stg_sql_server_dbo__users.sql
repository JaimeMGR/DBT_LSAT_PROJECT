-- ===========================================================================
-- stg_sql_server_dbo__users.sql
-- ===========================================================================
-- CAPA: Staging
-- ORIGEN: source('sql_server_dbo', 'users')
-- DESTINO (DEV): <ALUMNO>_DEV_SILVER_DB.sql_server_dbo.stg_sql_server_dbo__users
-- MATERIALIZACIÓN: view
--
-- OBJETIVO:
--   Renombrado y casteado de la tabla users. Filtramos los soft-deletes de
--   Fivetran porque esos registros no son válidos.
-- ===========================================================================

with src_users as (

    select *
    from {{ source('sql_server_dbo', 'users') }}
    -- Filtramos los borrados lógicos. Esta es una de las pocas
    -- transformaciones de "limpieza" permitidas en staging.
    where coalesce(_fivetran_deleted, false) = false

),

renamed_casted as (

    select
          user_id
        , first_name
        , last_name
        , email
        , phone_number
        , address_id
        , created_at                 as created_at_utc
        , updated_at                 as updated_at_utc
        , _fivetran_synced           as date_load
    from src_users

)

select * from renamed_casted
