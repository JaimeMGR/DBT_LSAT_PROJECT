# Arquitectura del proyecto

Este documento describe la arquitectura del proyecto dbt de ejemplo del curso.

## Capas

El proyecto sigue un patrón en tres capas inspirado en Kimball:

```
        BRONZE (raw)              SILVER (transformed)         GOLD (consumable)
   <ALUMNO>_*_BRONZE_DB     →   <ALUMNO>_*_SILVER_DB      →    <ALUMNO>_*_GOLD_DB
   ───────────────────          ────────────────────           ─────────────────
   sql_server_dbo.users         staging.stg_*                  core.dim_users
   sql_server_dbo.orders        snapshots.*_snp                core.dim_products
   google_sheets.budget                                        core.fct_orders
                                                               core.fct_order_items
                                                               core.fct_events
                                                               product.fct_user_sessions
                                                               marketing.fct_user_purchases
```

### Bronze (raw)
- Datos crudos cargados desde Fivetran/Google Sheets/SQL Server.
- **No se modifica con dbt**. dbt solo declara estos datos como `source()`.
- Schemas: `sql_server_dbo`, `google_sheets`.

### Silver (staging)
- Modelos `stg_*`: una vista por cada tabla source con renombrado y casteado.
- Sin lógica de negocio. Sin joins (excepto en algún caso muy puntual).
- Schemas: `staging.sql_server_dbo`, `staging.google_sheets`.
- **Snapshots**: viven aquí también, en el schema `snapshots`.

### Gold (marts)
- **Core**: dimensiones (`dim_*`) y hechos (`fct_*`) compartidos por toda la
  organización. Schema `core`.
- **Intermediate**: vistas auxiliares reutilizadas por varios marts. Schema
  `intermediate`. NO se exponen a usuarios finales.
- **Marts por dominio**: `product`, `marketing`. Cada uno tiene sus propios
  modelos optimizados para sus stakeholders.

## Lineage de un caso completo

Para fct_user_purchases (mart de Marketing):

```
source('sql_server_dbo','users')      ──┐
source('sql_server_dbo','orders')     ──┤
source('sql_server_dbo','order_items')──┼──→ stg_*  ──→  int_orders__enriched
source('sql_server_dbo','addresses')  ──┤                     │
source('sql_server_dbo','promos')     ──┘                     ▼
                                                          fct_orders
                                                              │
                                                              │
                                              fct_order_items │
                                                          \   │   /
                                                           \  │  /
                                                            \ │ /
                                                             \│/
                                                              ▼
                                                      fct_user_purchases
```

## Convenciones de nombrado

| Tipo            | Patrón                                | Ejemplo                              |
|-----------------|---------------------------------------|--------------------------------------|
| Source          | `<schema>.<entidad>`                  | `sql_server_dbo.orders`              |
| Staging         | `stg_<source>__<entidad>`             | `stg_sql_server_dbo__users`          |
| Intermediate    | `int_<dominio>__<verbo>`              | `int_orders__enriched`               |
| Dimension       | `dim_<entidad>`                       | `dim_users`                          |
| Fact            | `fct_<entidad>`                       | `fct_orders`                         |
| Snapshot        | `<entidad>_snapshot_<estrategia>`     | `users_snapshot_timestamp`           |
| Test singular   | `assert_<regla>`                      | `assert_delivery_after_order`        |

## Comandos clave

```bash
dbt deps                                      # Instalar packages
dbt seed                                      # Cargar CSVs como tablas
dbt run                                       # Ejecutar todos los modelos
dbt run --select staging                      # Solo staging
dbt run --select +fct_orders                  # fct_orders y sus padres
dbt run --select stg_sql_server_dbo__users+   # users y sus hijos
dbt test                                      # Ejecutar todos los tests
dbt build                                     # seed + run + snapshot + test (en orden)
dbt snapshot                                  # Ejecutar snapshots
dbt docs generate && dbt docs serve           # Generar y servir documentación
dbt source freshness                          # Validar freshness de los sources
```
