{% snapshot games_raw_snapshot %}

{{
    config(
        target_database = 'DEV_BRONZE_DB_STEAM' if target.name == 'dev' else 'PRO_BRONZE_DB_STEAM',
        target_schema   = 'SNAPSHOTS',
        unique_key      = 'LINK',
        strategy        = 'timestamp',
        updated_at      = '_LOADED_AT'
    )
}}

/*
  SNAPSHOT: games_raw_snapshot
  CAPA:     Bronze
  ORIGEN:   DEV_BRONZE_DB_STEAM.KAGGLE.GAMES_RAW

  Propósito:
    Implementa una dimensión de cambio lento tipo 2 (SCD-2) sobre la tabla raw.
    Registra el historial de cambios en los datos de un juego a lo largo del tiempo:
    cambios en reseñas, picos de jugadores o cualquier otro campo que varíe
    entre cargas sucesivas del dataset.

  Estrategia: timestamp sobre _LOADED_AT
    - Cada vez que se cargue un nuevo fichero al stage, _LOADED_AT cambiará.
    - Si el LINK (identificador único del juego) ya existe con un _LOADED_AT
      más reciente, dbt invalidará el registro anterior (dbt_valid_to = now())
      y creará uno nuevo (dbt_valid_from = now()).

  Columnas añadidas por dbt:
    - dbt_valid_from  : fecha desde la que el registro es válido
    - dbt_valid_to    : fecha hasta la que el registro fue válido (NULL = vigente)
    - dbt_updated_at  : última actualización del registro
    - dbt_scd_id      : identificador único de cada versión del registro

  Ejecución: dbt snapshot
*/

SELECT
    LINK,
    GAME,
    RELEASE,
    PEAK_PLAYERS,
    POSITIVE_REVIEWS,
    NEGATIVE_REVIEWS,
    TOTAL_REVIEWS,
    RATING,
    PRIMARY_GENRE,
    PUBLISHER,
    DEVELOPER,
    REVIEW_PERCENTAGE,
    PLAYERS_RIGHT_NOW,
    HOUR_24_PEAK,
    ALL_TIME_PEAK,
    ALL_TIME_PEAK_DATE,
    _LOADED_AT,
    _SOURCE_FILE
FROM {{ source('kaggle', 'GAMES_RAW') }}

{% endsnapshot %}
