-- ===========================================================================
-- dim_dates.sql
-- ===========================================================================
-- CAPA: Marts/Core (Gold)
-- MATERIALIZACIÓN: table
--
-- OBJETIVO:
--   Dimensión de tiempo. Genera una fila por día desde 2020 hasta 2030
--   con todos los componentes temporales (año, mes, trimestre, día de la
--   semana, etc.) para facilitar análisis temporales.
--
-- IMPLEMENTACIÓN:
--   Usamos `dbt_utils.date_spine` que abstrae la generación de fechas y
--   funciona en todos los DWs soportados (Snowflake, BigQuery, Databricks).
--
-- HOOKS:
--   El pre-hook fija la zona horaria a Europe/Madrid solo durante la
--   construcción de este modelo.
-- ===========================================================================

{{ config(
    materialized='table',
    pre_hook="alter session set timezone = 'Europe/Madrid'"
) }}

with dates as (

    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2020-01-01' as date)",
        end_date="cast('2030-12-31' as date)"
    ) }}

),

final as (

    select
          date_day                                  as date
        , year(date_day)                            as year
        , month(date_day)                           as month
        , monthname(date_day)                       as month_name
        , day(date_day)                             as day
        , dayofweek(date_day)                       as number_week_day
        , dayname(date_day)                         as week_day
        , quarter(date_day)                         as quarter
        , weekiso(date_day)                         as week_of_year
        , year(date_day) * 100 + month(date_day)    as year_month
        , year(date_day) * 10000
            + month(date_day) * 100
            + day(date_day)                         as date_id
        , case
            when dayofweek(date_day) in (0, 6) then true
            else false
          end                                       as is_weekend

    from dates

)

select * from final
