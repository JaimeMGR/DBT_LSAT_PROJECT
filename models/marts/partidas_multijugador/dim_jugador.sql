{{ config(materialized = 'table') }}

/*
  DIMENSIÓN: dim_jugador
  MART:      Partidas multijugador
  ORIGEN:    stg_kaggle__player

  Una fila = un jugador. El email ya viene hasheado desde staging.
*/

SELECT
    {{ dbt_utils.generate_surrogate_key(['player_id']) }}       AS id_jugador,
    player_id                                                   AS id_jugador_natural,
    nickname,
    edad,
    fecha_nacimiento,
    mail_hash,
    fecha_creacion_perfil
FROM {{ ref('stg_kaggle__player') }}
