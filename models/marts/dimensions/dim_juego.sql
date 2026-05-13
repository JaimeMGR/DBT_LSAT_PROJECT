{{
    config(
        materialized = 'table'
    )
}}

/*
  MODELO: dim_juego
  CAPA:   Marts / Dimensions (Gold)
  DESCRIPCIÓN: Dimensión de juego con sus atributos descriptivos.
*/

WITH stg AS (
    SELECT * FROM {{ ref('stg_kaggle__games') }}
),

pub_dev AS (
    SELECT * FROM {{ ref('int_games__publishers_developers_normalized') }}
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['stg.id_steam']) }}    AS id_juego,
    stg.id_steam,
    stg.nombre_juego                                            AS nombre,
    stg.link                                                    AS enlace,
    stg.fecha_mod_tienda,
    pub_dev.es_indie
FROM stg
LEFT JOIN pub_dev ON stg.id_steam = pub_dev.id_steam
WHERE stg.id_steam IS NOT NULL
