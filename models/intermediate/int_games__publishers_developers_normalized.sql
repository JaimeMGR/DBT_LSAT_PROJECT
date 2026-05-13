{{
    config(
        materialized = 'view'
    )
}}

/*
  MODELO: int_games__publishers_developers_normalized
  CAPA:   Intermediate (Silver)
  ORIGEN: stg_kaggle__games

  Propósito:
    Publisher y developer pueden contener varios nombres separados por coma.
    Este modelo extrae el primero como entidad principal y calcula
    si el juego es indie (mismo desarrollador y editor o publisher
    contiene "indie" en géneros).
    También calcula el total de juegos por desarrollador.
*/

WITH stg AS (

    SELECT
        id_steam,
        nombre_juego,
        publisher,
        developer,
        genero_primario,
        store_genres,
        fecha_lanzamiento
    FROM {{ ref('stg_kaggle__games') }}
    WHERE id_steam IS NOT NULL

),

normalizado AS (

    SELECT
        id_steam,
        nombre_juego,
        fecha_lanzamiento,

        -- Publisher principal: primer elemento de la lista
        TRIM(SPLIT_PART(publisher, ',', 1))     AS publisher_principal,

        -- Developer principal: primer elemento de la lista
        TRIM(SPLIT_PART(developer, ',', 1))     AS developer_principal,

        -- Flag indie: el género incluye "Indie"
        CASE
            WHEN UPPER(store_genres) LIKE '%INDIE%'
            THEN TRUE
            ELSE FALSE
        END                                     AS es_indie,

        publisher,
        developer

    FROM stg

),

-- Total de juegos por desarrollador
conteo_dev AS (

    SELECT
        developer_principal,
        COUNT(*) AS total_juegos_dev
    FROM normalizado
    WHERE developer_principal IS NOT NULL
    GROUP BY 1

),

-- Total de juegos por publisher
conteo_pub AS (

    SELECT
        publisher_principal,
        COUNT(*) AS total_juegos_pub
    FROM normalizado
    WHERE publisher_principal IS NOT NULL
    GROUP BY 1

)

SELECT
    n.id_steam,
    n.nombre_juego,
    n.fecha_lanzamiento,
    n.publisher_principal,
    n.developer_principal,
    n.es_indie,
    COALESCE(cd.total_juegos_dev, 0)    AS total_juegos_dev,
    COALESCE(cp.total_juegos_pub, 0)    AS total_juegos_pub
FROM normalizado n
LEFT JOIN conteo_dev cd
       ON n.developer_principal = cd.developer_principal
LEFT JOIN conteo_pub cp
       ON n.publisher_principal = cp.publisher_principal
