-- ===========================================================================
-- stg_google_sheets__budget.sql
-- ===========================================================================
-- CAPA: Staging
-- ORIGEN: source('google_sheets', 'budget')
-- DESTINO (DEV): <ALUMNO>_DEV_SILVER_DB.google_sheets.stg_google_sheets__budget
-- MATERIALIZACIÓN: view (heredada de dbt_project.yml)
--
-- OBJETIVO:
--   Capa de "renombrado y casteado" sobre el source `budget`.
--   Aquí NO aplicamos lógica de negocio — solo convenciones de nombres,
--   tipos correctos y selección de columnas relevantes.
--
-- BUENAS PRÁCTICAS:
--   1. Una sola CTE por source (referenciada con `source()`)
--   2. Una CTE de "renamed_casted" donde casteamos y renombramos
--   3. Un `select * from <última_cte>` final (legibilidad y debugging fácil)
-- ===========================================================================

with src_budget as (

    select *
    from {{ source('google_sheets', 'budget') }}

),

renamed_casted as (

    select
          _row                       as budget_id
        , product_id
        , quantity                   as quantity_budgeted
        , month::date                as budget_month
        , _fivetran_synced           as date_load
    from src_budget

)

select * from renamed_casted
