# Steam Games — Proyecto dbt + Snowflake + Power BI

## ENLACE A PRESENTACIÓN 

https://prezi.com/p/f9fuudbfxwnh/#opensidebar=prezi-video-choose-mode

## Descripción

Pipeline de datos completo end-to-end para analizar el catálogo de Steam
(~67.000 juegos) y un dominio simulado de partidas multijugador.

Arquitectura medallion **Bronze → Silver → Gold** con dbt Cloud y Snowflake,
consumido en Power BI con un tema visual inspirado en la plataforma de Steam.

El dataset incluye un ~10% de datos sucios inyectados intencionalmente (typos,
nulos disfrazados, fechas mal formateadas, duplicados) para demostrar las
técnicas de limpieza y testing de datos.

## Stack tecnológico

- **Snowflake** — data warehouse (Bronze / Silver / Gold, DEV y PRO)
- **dbt Cloud** — transformación, testing, documentación y orquestación
- **Power BI** — visualización y cuadros de mando con tema Steam
- **Python** — generación de los datos simulados de partidas

## Arquitectura

```
Bronze (raw)        Silver (clean + normalizado)      Gold (dimensional)
─────────────       ────────────────────────────      ──────────────────
GAMES_RAW      ──►  staging (4 modelos)          ──►  Mart Catálogo de juegos
MATCH          ──►  intermediate (11 modelos)         ├─ dim_juego
PLAYER              normalizado según el ERD          ├─ dim_fecha
MATCH_PLAYER                                          ├─ dim_editor
                                                      ├─ dim_desarrollador
                                                      ├─ dim_genero
                                                      ├─ dim_tecnologia
                                                      ├─ dim_segmento (seed)
                                                      ├─ puente_juego_genero
                                                      ├─ puente_juego_tecnologia
                                                      └─ fct_juego (incremental)

                                                      Mart Partidas multijugador
                                                      ├─ dim_jugador
                                                      ├─ dim_gamemode
                                                      ├─ dim_region
                                                      └─ fct_match_player (incremental)
```

## Bases de datos Snowflake

| Entorno | Bronze                | Silver                | Gold                |
|---------|-----------------------|-----------------------|---------------------|
| DEV     | DEV_BRONZE_DB_STEAM   | DEV_SILVER_DB_STEAM   | DEV_GOLD_DB_STEAM   |
| PRO     | PRO_BRONZE_DB_STEAM   | PRO_SILVER_DB_STEAM   | PRO_GOLD_DB_STEAM   |

El entorno se resuelve con la variable `DBT_ENVIRONMENTS` (valores `DEV` o `PRO`),
configurada en cada entorno de dbt Cloud.

## Estructura del proyecto

```
steam_games/
├── analyses/                      # Consultas SQL ad-hoc (no generan modelos)
├── macros/                        # Funciones Jinja/SQL y tests genéricos custom
│   ├── limpiar_texto.sql
│   ├── parsear_fecha.sql
│   ├── obtener_segmento.sql
│   ├── generate_schema_name.sql
│   ├── test_kda_valido.sql
│   ├── test_fecha_no_futura.sql
│   ├── test_rango_porcentaje.sql
│   └── test_fecha_fin_posterior_inicio.sql
├── models/
│   ├── staging/                   # Silver: limpieza y tipado (view)
│   │   ├── _kaggle__sources.yml
│   │   ├── _stg_kaggle__models.yml
│   │   ├── stg_kaggle__games.sql
│   │   ├── stg_kaggle__match.sql
│   │   ├── stg_kaggle__player.sql
│   │   └── stg_kaggle__match_player.sql
│   ├── intermediate/              # Silver: normalización según el ERD (view)
│   │   ├── _intermediate__models.yml
│   │   ├── int_games__games.sql
│   │   ├── int_games__game_metrics.sql
│   │   ├── int_games__publishers.sql
│   │   ├── int_games__developers.sql
│   │   ├── int_games__genres.sql
│   │   ├── int_games__game_genres.sql
│   │   ├── int_games__technology_types.sql
│   │   ├── int_games__game_technologies.sql
│   │   ├── int_match__gamemodes.sql
│   │   ├── int_match__regions.sql
│   │   └── int_match__matches.sql
│   └── marts/                     # Gold: tablas para Power BI (table)
│       ├── catalogo_juegos/
│       │   ├── _catalogo_juegos__models.yml
│       │   ├── dim_juego.sql
│       │   ├── dim_fecha.sql
│       │   ├── dim_editor.sql
│       │   ├── dim_desarrollador.sql
│       │   ├── dim_genero.sql
│       │   ├── dim_tecnologia.sql
│       │   ├── dim_segmento.sql
│       │   ├── puente_juego_genero.sql
│       │   ├── puente_juego_tecnologia.sql
│       │   └── fct_juego.sql
│       └── partidas_multijugador/
│           ├── _partidas__models.yml
│           ├── dim_jugador.sql
│           ├── dim_gamemode.sql
│           ├── dim_region.sql
│           └── fct_match_player.sql
├── seeds/                         # CSVs estáticos de referencia
│   ├── _seeds.yml
│   └── seed_segmentos.csv
├── snapshots/                     # Capturas SCD tipo 2
│   └── games_raw_snapshot.sql
├── tests/                         # Tests singulares personalizados
│   ├── assert_resenas_coherentes.sql
│   ├── assert_porcentaje_coherente.sql
│   ├── assert_metricas_no_negativas.sql
│   └── assert_fct_sin_juegos_huerfanos.sql
├── generar_datos_multijugador.py  # Script Python para generar los datos
├── dbt_project.yml
├── packages.yml
└── profiles.yml                   # ⚠ NO subir a Git (.gitignore)
```

## Capas en detalle

### Bronze

Cuatro tablas raw cargadas tal cual desde CSV, todos los campos como `VARCHAR`
para que ningún dato corrupto rompa la ingesta. Incluye columnas de auditoría
`_LOADED_AT` y `_SOURCE_FILE`.

### Silver

- **Staging** — limpieza, tipado y eliminación de duplicados. Relación 1:1
  con las tablas de Bronze. Materialización `view`. Incluye anonimización del
  email del jugador con hash MD5 por privacidad.
- **Intermediate** — normalización en 13 entidades según el modelo
  entidad-relación, organizadas en dos dominios (juegos y partidas).

### Gold

Dos data marts en esquema estrella:

- **Catálogo de juegos** — `fct_juego` (incremental) con 7 dimensiones y
  2 tablas puente para las relaciones N:M.
- **Partidas multijugador** — `fct_match_player` (incremental) con
  granularidad jugador-partida (~400.000 filas).

`dim_juego` y `dim_fecha` son **dimensiones conformadas** compartidas entre
ambos marts.

## Generación de datos

El dominio de partidas multijugador no existe en el dataset original de
Kaggle. Se generan con un script de Python:

```bash
python generar_datos_multijugador.py
```

Produce tres CSV que luego se cargan en Bronze:
- `matches.csv` — 50.000 partidas
- `players.csv` — 5.000 jugadores
- `match_player.csv` — ~400.000 filas de estadísticas KDA

El script usa solo los 18 juegos multijugador reales del dataset e inyecta
suciedad realista (typos, mayúsculas inconsistentes) para reproducir el
aspecto de datos reales.

## Comandos principales

```bash
# Instalar paquetes
dbt deps

# Cargar seeds (necesario antes del primer run)
dbt seed

# Ejecutar todos los modelos
dbt run

# Construir todo en orden (seeds + modelos + tests + snapshots)
dbt build

# Reconstruir desde cero (limpia el incremental)
dbt build --full-refresh

# Solo una capa
dbt run --select staging
dbt run --select intermediate
dbt run --select marts

# Ejecutar tests
dbt test

# Snapshot SCD-2
dbt snapshot

# Documentación
dbt docs generate
dbt docs serve
```

## Orquestación — Jobs en dbt Cloud

Tres jobs configurados en `Deploy → Jobs`:

| Job                  | Trigger              | Comandos                                          |
|----------------------|----------------------|---------------------------------------------------|
| `daily_full_refresh` | Manual               | `dbt deps → seed → run → test → snapshot`         |
| `docs_generate`      | Manual               | `dbt docs generate`                               |
| `ci_check`           | Pull Request         | `dbt build` con `state:modified+`                 |

Los jobs están en manual (no programados) como decisión consciente para no
consumir créditos en un proyecto de desarrollo. En un entorno real bastaría
con activar el cron en `Settings → Triggers → Schedule`.

## Testing

El proyecto valida la calidad de los datos con tres tipos de test:

- **Genéricos** — `unique`, `not_null`, `accepted_range`, `relationships`
  declarados en los ficheros YAML.
- **Custom** — tests genéricos creados para este dataset, ubicados en
  `macros/`: `kda_valido`, `fecha_no_futura`, `rango_porcentaje`,
  `fecha_fin_posterior_inicio`.
- **Singulares** — reglas de negocio en SQL: coherencia de reseñas,
  coherencia de porcentajes, métricas no negativas e integridad referencial.

Los tests que detectan los datos sucios inyectados a propósito usan
`severity: warn` — avisan pero no bloquean, porque es ruido conocido del
origen, no un fallo del pipeline.

## Decisiones de diseño

| Área | Decisión | Razón |
|------|----------|-------|
| Arquitectura | Medallion Bronze/Silver/Gold | Separa responsabilidades, cada capa con una función |
| Bronze | Todo VARCHAR | Ningún dato corrupto rompe la ingesta |
| Silver | Staging 1:1 con el origen | Convención de dbt, la normalización va en intermediate |
| Silver | Hash MD5 del email | Privacidad: anonimizar identificadores personales |
| Gold | Modelo en estrella | Consultas rápidas desde Power BI |
| Gold | Dimensiones conformadas | `dim_juego` y `dim_fecha` permiten cruzar análisis entre marts |
| Gold | Tablas puente | Resuelven relaciones muchos a muchos (géneros, tecnologías) |
| Gold | Claves surrogadas | Independencia del sistema de origen |
| Performance | `fct_juego` y `fct_match_player` incrementales | Solo crecen — reconstruir 400k filas cada vez sería un desperdicio |
| Performance | Silver como vistas, Gold como tablas | Vistas no ocupan espacio, tablas se consultan rápido |
| SCD | Un único snapshot, sobre `GAMES_RAW` | Solo donde los datos cambian: las partidas son inmutables |
| Entornos | `env_var('DBT_ENVIRONMENTS')` | dbt Cloud usa target `default`, no `dev` |
| Orquestación | Jobs en manual, no programados | No consumir créditos innecesarios |
| Calidad | Tests de datos sucios como WARN | No son bugs, es ruido conocido del origen |

## Power BI — Casos de uso

| Dashboard                     | Qué analiza                                          |
|-------------------------------|------------------------------------------------------|
| Top 10 jugadores por KDA      | Ranking de rendimiento por juego, modo y región      |
| Análisis de géneros           | Géneros dominantes y su valoración media             |
| Estudios y desarrolladoras    | Editores y desarrolladores más exitosos              |
| Rendimiento de tecnologías    | Engines de los juegos de éxito: popularidad vs calidad |

El informe usa el fichero `Tema_Steam.json` con la paleta visual de la
plataforma (azul oscuro `#1B2838`, azul claro `#66C0F4`, verde lima `#A4D007`).

## Convenciones de nomenclatura

| Capa         | Prefijo   | Ejemplo                          |
|--------------|-----------|----------------------------------|
| Staging      | `stg_`    | `stg_kaggle__games`              |
| Intermediate | `int_`    | `int_games__games`               |
| Dimensions   | `dim_`    | `dim_juego`, `dim_fecha`         |
| Facts        | `fct_`    | `fct_juego`, `fct_match_player`  |
| Puentes      | `puente_` | `puente_juego_genero`            |
| Seeds        | `seed_`   | `seed_segmentos`                 |

## Notas operativas

**Cuando cambies la lógica de un modelo incremental** (filtros, JOINs, lógica
de negocio), reconstruye con `--full-refresh` para que el cambio se aplique
a todas las filas, no solo a las nuevas:

```bash
dbt build --full-refresh
```

**Cuando cambies algo que afecta a un data mart**, reconstruye el mart entero
(no solo el modelo modificado) para que la tabla de hechos y sus dimensiones
queden coherentes entre sí:

```bash
dbt run --select catalogo_juegos --full-refresh
```
