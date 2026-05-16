{{ config(materialized = 'table') }}

/*
  DIMENSIÓN: dim_fecha
  MART:      Compartida (catálogo + partidas)
  ORIGEN:    generada con dbt_utils.date_spine

  Calendario completo de 2000 a 2030 garantizando que no
  haya huecos para análisis temporales en Power BI.
*/

WITH spine AS (

    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2000-01-01' as date)",
        end_date="cast('2030-01-01' as date)"
    ) }}

)

SELECT
    {{ dbt_utils.generate_surrogate_key(['date_day']) }}        AS id_fecha,
    date_day                                                    AS fecha_completa,
    YEAR(date_day)                                              AS anio,
    QUARTER(date_day)                                           AS trimestre,
    MONTH(date_day)                                             AS mes,
    MONTHNAME(date_day)                                         AS nombre_mes,
    DAY(date_day)                                               AS dia,
    DAYNAME(date_day)                                           AS nombre_dia,
    DAYOFWEEKISO(date_day)                                      AS dia_semana,
    CASE WHEN DAYOFWEEKISO(date_day) IN (6, 7)
         THEN TRUE ELSE FALSE END                               AS es_fin_de_semana
FROM spine
