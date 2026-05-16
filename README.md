# Steam Games — Proyecto dbt + Snowflake + Power BI

## Descripción
Pipeline de datos completo para analizar el catálogo de Steam (~67.000 juegos).  
Arquitectura medallion: **Bronze → Silver → Gold** con dbt Cloud y Snowflake.

## Arquitectura

```
Bronze (raw)      Silver (clean)         Gold (dimensional)
─────────────     ──────────────         ──────────────────
GAMES_RAW    ──►  stg_kaggle__games  ──►  dim_juego
                  int_genres_...     ──►  dim_fecha
                  int_technologies.. ──►  dim_desarrollador
                  int_publishers_..  ──►  dim_editor
                                    ──►  dim_genero
                                    ──►  dim_tecnologia
                                    ──►  dim_segmento
                                    ──►  fct_actividad_juego
```

## Bases de datos Snowflake

| Entorno | Bronze             | Silver             | Gold             |
|---------|--------------------|--------------------|------------------|
| DEV     | DEV_BRONZE_DB      | DEV_SILVER_DB      | DEV_GOLD_DB      |
| PRO     | PRO_BRONZE_DB      | PRO_SILVER_DB      | PRO_GOLD_DB      |

## Estructura del proyecto

```
steam_games/
├── analyses/              # Consultas SQL ad-hoc (no generan modelos)
├── macros/                # Funciones reutilizables en Jinja/SQL
├── models/
│   ├── staging/           # Silver: limpieza y tipado (view)
│   │   ├── _kaggle__sources.yml
│   │   ├── _stg_kaggle__models.yml
│   │   └── stg_kaggle__games.sql
│   ├── intermediate/      # Silver: lógica reutilizable (view)
│   │   ├── int_games__genres_unpivoted.sql
│   │   ├── int_games__technologies_unpivoted.sql
│   │   └── int_games__publishers_developers_normalized.sql
│   └── marts/             # Gold: tablas para Power BI (table)
│       ├── dimensions/
│       │   ├── dim_juego.sql
│       │   ├── dim_fecha.sql
│       │   ├── dim_desarrollador.sql
│       │   ├── dim_editor.sql
│       │   ├── dim_genero.sql
│       │   ├── dim_tecnologia.sql
│       │   └── dim_segmento.sql
│       └── facts/
│           └── fct_actividad_juego.sql
├── seeds/                 # CSVs estáticos de referencia
├── snapshots/             # Capturas SCD tipo 2
├── tests/                 # Tests singulares personalizados
├── dbt_project.yml
├── packages.yml
└── profiles.yml           # ⚠ NO subir a Git (.gitignore)
```

## Comandos principales

```bash
# Instalar paquetes
dbt deps

# Ejecutar todos los modelos
dbt run

# Solo staging
dbt run --select staging

# Solo Gold
dbt run --select marts

# Ejecutar tests
dbt test

# Generar y servir documentación
dbt docs generate
dbt docs serve

# Ejecutar en producción
dbt run --target pro
```

## Convenciones de nomenclatura

| Capa         | Prefijo   | Ejemplo                                      |
|--------------|-----------|----------------------------------------------|
| Staging      | `stg_`    | `stg_kaggle__games`                          |
| Intermediate | `int_`    | `int_games__genres_unpivoted`                |
| Dimensions   | `dim_`    | `dim_juego`, `dim_fecha`                     |
| Facts        | `fct_`    | `fct_actividad_juego`                        |
