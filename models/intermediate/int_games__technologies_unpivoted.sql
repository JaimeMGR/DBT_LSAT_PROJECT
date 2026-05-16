{{
    config(
        materialized = 'view'
    )
}}

/*
  MODELO: int_games__technologies_unpivoted
  CAPA:   Intermediate (Silver)
  ORIGEN: stg_kaggle__games

  Propósito:
    El campo detected_technologies contiene tecnologías separadas por "; "
    por ejemplo: "Engine.GameMaker; SDK.FMOD; SDK.cURL"
    Este modelo la explota en una fila por tecnología, separando
    el tipo (Engine, SDK, etc.) del nombre concreto.

  Ejemplo de salida:
    id_steam | tipo_tecnologia | nombre_tecnologia
    2231450  | Engine          | GameMaker
    2231450  | SDK             | FMOD
*/

WITH stg AS (

    SELECT
        id_steam,
        detected_technologies
    FROM {{ ref('stg_kaggle__games') }}
    WHERE detected_technologies IS NOT NULL
      AND id_steam IS NOT NULL

),

-- Explotar por punto y coma
tecnologias_explotadas AS (

    SELECT
        s.id_steam,
        TRIM(t.VALUE::STRING) AS tecnologia_raw
    FROM stg s,
    LATERAL SPLIT_TO_TABLE(s.detected_technologies, ';') t
    WHERE TRIM(t.VALUE::STRING) != ''

),

-- Separar tipo y nombre: "Engine.GameMaker" → tipo="Engine", nombre="GameMaker"
tecnologias_parseadas AS (

    SELECT
        id_steam,

        -- Tipo: todo lo que está antes del primer punto
        TRIM(SPLIT_PART(tecnologia_raw, '.', 1))    AS tipo_tecnologia,

        -- Nombre: todo lo que está después del primer punto
        TRIM(SPLIT_PART(tecnologia_raw, '.', 2))    AS nombre_tecnologia,

        tecnologia_raw

    FROM tecnologias_explotadas
    WHERE tecnologia_raw LIKE '%.%'   -- Asegura que tiene el formato Tipo.Nombre

)

SELECT
    id_steam,
    tipo_tecnologia,
    nombre_tecnologia
FROM tecnologias_parseadas
