# 🎓 Repo de ejemplo — Curso dbt Platform + Snowflake

> Repositorio de referencia para el curso de **Data Engineering con dbt y Snowflake**.
> Caso de uso: **e-commerce ficticio** con datos transaccionales (SQL Server)
> y operativos (Google Sheets).

Este repo es un proyecto dbt **completo y funcional** que recoge todo lo que
hemos visto a lo largo del curso: sources, staging, intermediate, marts, tests,
docs, snapshots, seeds, macros, jinja, modelos incrementales, microbatch,
data contracts, unit tests, hooks y operaciones.

Está pensado como **referencia consultable**: cada archivo está comentado
explicando *qué hace*, *por qué se hace así* y *qué módulo del curso lo cubre*.

---

## 📑 Tabla de contenidos

- [Pre-requisitos](#pre-requisitos)
- [Estructura del proyecto](#estructura-del-proyecto)
- [Caso de uso del e-commerce](#caso-de-uso-del-e-commerce)
- [Setup inicial](#setup-inicial)
- [Cómo ejecutar el proyecto](#cómo-ejecutar-el-proyecto)
- [Mapa de módulos del curso → archivos del repo](#mapa-de-módulos-del-curso--archivos-del-repo)
- [Errores comunes y soluciones](#errores-comunes-y-soluciones)

---

## Pre-requisitos

Antes de poder ejecutar este proyecto, asegúrate de tener:

- ✅ Acceso a la cuenta de **Snowflake** del curso (`civicapartner.west-europe.azure`)
- ✅ Tu rol asignado: `CURSO_DATA_ENGINEERING`
- ✅ Tus tres bases de datos de **DEV** creadas en Snowflake:
  - `<ALUMNOX>_DEV_BRONZE_DB`
  - `<ALUMNOX>_DEV_SILVER_DB`
  - `<ALUMNOX>_DEV_GOLD_DB`
- ✅ El warehouse `WH_CURSO_DATA_ENGINEERING` con permisos USAGE
- ✅ La variable de entorno **`DBT_ENVIRONMENTS`** configurada en tu profile
  de dbt Cloud apuntando a `<ALUMNOX>_DEV` (sin sufijo `_BRONZE_DB`).
- ✅ El esquema `sql_server_dbo` ya poblado con los datos del curso en tu
  base de datos `<ALUMNOX>_DEV_BRONZE_DB`.

---

## Estructura del proyecto

```
dbt-curso-ejemplo/
├── README.md                                 ← Este archivo
├── dbt_project.yml                           ← Configuración central del proyecto
├── packages.yml                              ← Dependencias externas (dbt_utils, codegen, ...)
├── profiles.yml.example                      ← Plantilla de profile para dbt Core
├── .gitignore
│
├── models/
│   ├── staging/                              ← Capa Silver (vistas)
│   │   ├── google_sheets/
│   │   │   ├── _google_sheets__sources.yml
│   │   │   ├── _google_sheets__models.yml
│   │   │   └── stg_google_sheets__budget.sql
│   │   └── sql_server_dbo/
│   │       ├── _sql_server_dbo__sources.yml
│   │       ├── _sql_server_dbo__models.yml
│   │       ├── stg_sql_server_dbo__addresses.sql
│   │       ├── stg_sql_server_dbo__events.sql
│   │       ├── stg_sql_server_dbo__events_incremental.sql      ← Patrón clásico is_incremental()
│   │       ├── stg_sql_server_dbo__events_microbatch.sql       ← Estrategia microbatch (dbt 1.9+)
│   │       ├── stg_sql_server_dbo__order_items.sql
│   │       ├── stg_sql_server_dbo__orders.sql
│   │       ├── stg_sql_server_dbo__products.sql
│   │       ├── stg_sql_server_dbo__promos.sql
│   │       └── stg_sql_server_dbo__users.sql
│   │
│   └── marts/                                ← Capa Gold (tablas)
│       ├── core/
│       │   ├── _core__models.yml             ← Tests + data contracts + unit tests
│       │   ├── _core__docs.md                ← Bloques markdown reutilizables
│       │   ├── intermediate/
│       │   │   ├── _intermediate__models.yml
│       │   │   ├── int_orders__enriched.sql
│       │   │   └── int_events__aggregated_by_user.sql
│       │   ├── dim_addresses.sql
│       │   ├── dim_dates.sql                 ← Usa dbt_utils.date_spine + pre-hook
│       │   ├── dim_products.sql
│       │   ├── dim_users.sql                 ← Con DATA CONTRACT
│       │   ├── fct_events.sql
│       │   ├── fct_order_items.sql
│       │   └── fct_orders.sql
│       │
│       ├── product/                          ← Mart del equipo de Producto (Ej. 19.1)
│       │   ├── _product__models.yml
│       │   └── fct_user_sessions.sql
│       │
│       └── marketing/                        ← Mart del equipo de Marketing (Ej. 19.2)
│           ├── _marketing__models.yml
│           └── fct_user_purchases.sql
│
├── snapshots/                                ← Cuatro estrategias de snapshot
│   ├── _snapshots.yml
│   ├── budget_snapshot_check.sql             ← strategy='check'
│   ├── budget_snapshot_hard_deletes.sql      ← hard_deletes='new_record'
│   ├── budget_snapshot_timestamp.sql         ← strategy='timestamp'
│   └── users_snapshot_timestamp.sql          ← Auditoría de usuarios
│
├── seeds/
│   ├── _seeds.yml
│   └── country_codes.csv                     ← Tabla de mapeo ISO 3166
│
├── macros/
│   ├── cents_to_dollars.sql                  ← Macro de utilidad (ejemplo simple)
│   ├── generate_schema_name.sql              ← Override del comportamiento por defecto de dbt
│   ├── obtener_valores.sql                   ← Devuelve valores DISTINCT (compile-time)
│   └── positive_values.sql                   ← Test genérico custom
│
├── tests/
│   ├── singular/
│   │   ├── assert_delivery_after_order.sql           ← Regla de negocio
│   │   └── assert_orders_match_order_items.sql       ← Cuadre cross-modelo
│   └── fixtures/
│       └── users_email_fixture.csv                   ← Datos para unit tests
│
├── analyses/
│   └── ejercicios_modulo_19.sql              ← Soluciones a los ejercicios prácticos
│
└── docs/
    └── architecture.md                       ← Lineage y convenciones del proyecto
```

---

## Caso de uso del e-commerce

El proyecto modela un e-commerce ficticio con dos sistemas fuente:

### Source `sql_server_dbo` (sistema transaccional)

| Tabla         | Descripción                                                  |
|---------------|--------------------------------------------------------------|
| `users`       | Usuarios registrados en la plataforma                        |
| `orders`      | Pedidos realizados (1 fila por pedido)                       |
| `order_items` | Detalle de productos en cada pedido (1 fila por línea)       |
| `products`    | Catálogo de productos                                        |
| `addresses`   | Direcciones de envío de los usuarios                         |
| `promos`      | Códigos promocionales aplicables a los pedidos               |
| `events`      | Eventos de navegación (page_view, add_to_cart, checkout, ...)|

### Source `google_sheets` (datos operativos)

| Tabla    | Descripción                              |
|----------|------------------------------------------|
| `budget` | Presupuesto mensual por producto         |

---

## Setup inicial

### 1️⃣ Variable de entorno `DBT_ENVIRONMENTS`

Ve a tu **Profile Settings → Credentials → este proyecto** y configura:

```
DBT_ENVIRONMENTS = ALUMNOX_DEV
```

(Sustituye `ALUMNOX` por tu identificador real, p.ej. `ALUMNO32_DEV`).

### 2️⃣ Instalar paquetes

Desde la consola de dbt Cloud:

```bash
dbt deps
```

Esto descarga `dbt_utils`, `codegen`, `dbt_expectations` y `dbt_project_evaluator`
en el directorio `dbt_packages/`.

### 3️⃣ Cargar los seeds

```bash
dbt seed
```

Esto crea la tabla `country_codes` en `<ALUMNOX>_DEV_BRONZE_DB.seed_data`.

### 4️⃣ Validar la conexión

```bash
dbt debug
```

Si todo está OK verás `All checks passed!`.

### 5️⃣ Validar freshness de los sources

```bash
dbt source freshness
```

Si alguna tabla está stale, revisa si tu Bronze está poblada correctamente.

---

## Cómo ejecutar el proyecto

### Build completo (recomendado)

```bash
dbt build
```

`dbt build` ejecuta en orden y respetando dependencias: `seed → snapshot → run → test`.
Si algún test falla, los modelos downstream NO se construyen — protección automática.

### Comandos por capa

```bash
# Solo staging (vistas en SILVER)
dbt run --select staging

# Solo el dominio core (dims y facts)
dbt run --select marts.core

# Mart de Marketing
dbt run --select marts.marketing

# Un modelo y todos sus padres
dbt run --select +fct_user_purchases

# Un modelo y todos sus hijos
dbt run --select stg_sql_server_dbo__users+
```

### Tests

```bash
dbt test                                                  # Todos los tests
dbt test --select staging                                 # Solo de staging
dbt test --select dim_users,test_type:unit                # Solo unit tests de dim_users
dbt test --select test_name:unique                        # Solo tests de unicidad
dbt test --select assert_delivery_after_order             # Un test singular concreto
```

### Documentación

```bash
dbt docs generate
dbt docs serve            # En dbt Core. En dbt Cloud: botón "View Docs"
```

### Snapshots

```bash
dbt snapshot                                              # Todos
dbt snapshot --select users_snapshot_timestamp            # Uno concreto
```

### Modo full-refresh (reconstruir incrementales desde cero)

```bash
dbt run --full-refresh
dbt run --full-refresh --select stg_sql_server_dbo__events_incremental
```

---

## Mapa de módulos del curso → archivos del repo

| Módulo del curso                          | Archivos donde se cubre                                                                                                                |
|-------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------|
| **3. Seeds**                              | `seeds/country_codes.csv`, `seeds/_seeds.yml`                                                                                          |
| **4. Sources**                            | `models/staging/*/＿*__sources.yml`                                                                                                     |
| **5. Modelos**                            | Todos los `*.sql` en `models/`                                                                                                         |
| **5.5 Data contracts**                    | `models/marts/core/_core__models.yml` → `dim_users.config.contract`                                                                    |
| **6. Testing (genéricos + singulares)**   | YAMLs `_*__models.yml`, `tests/singular/*`, `macros/positive_values.sql`                                                               |
| **6. Unit tests**                         | `models/marts/core/_core__models.yml` → bloque `unit_tests:`, `tests/fixtures/users_email_fixture.csv`                                 |
| **7. Documentación**                      | YAMLs con `description:`, `models/marts/core/_core__docs.md`                                                                           |
| **8. Packages**                           | `packages.yml`                                                                                                                         |
| **9. Jinja**                              | `models/marts/core/intermediate/int_events__aggregated_by_user.sql`                                                                    |
| **10. Macros**                            | `macros/obtener_valores.sql`, `macros/cents_to_dollars.sql`, `macros/positive_values.sql`                                              |
| **11. Modelos incrementales**             | `stg_sql_server_dbo__events_incremental.sql` (clásico), `stg_sql_server_dbo__events_microbatch.sql` (estrategia microbatch)            |
| **12. Snapshots**                         | `snapshots/budget_snapshot_timestamp.sql`, `snapshots/budget_snapshot_check.sql`, `snapshots/budget_snapshot_hard_deletes.sql`, `snapshots/users_snapshot_timestamp.sql` |
| **13. Hooks**                             | `dbt_project.yml` (`on-run-start`), `models/marts/core/dim_dates.sql` (`pre_hook`)                                                    |
| **14. Operaciones**                       | `dbt run-operation generate_source ...` (uso del paquete codegen)                                                                      |
| **15. Variables**                         | `dbt_project.yml` → `vars:`, uso con `var()` y `env_var()` en sources/models                                                           |
| **16. Entornos**                          | Comentarios sobre target en `profiles.yml.example` y uso de `env_var('DBT_ENVIRONMENTS')`                                              |
| **17. Organización Snowflake**            | `dbt_project.yml` (databases por capa), `macros/generate_schema_name.sql`                                                              |
| **18. Jobs**                              | (Se configuran en la UI de dbt Cloud, no en el repo. Los hooks del `dbt_project.yml` los soportan).                                   |
| **19. Ejercicios prácticos**              | `models/marts/product/fct_user_sessions.sql` (Ej. 19.1), `models/marts/marketing/fct_user_purchases.sql` (Ej. 19.2), `analyses/ejercicios_modulo_19.sql` |

---

## Errores comunes y soluciones

### ❌ `Database 'ALUMNOX_FAIL_BRONZE_DB' does not exist`

**Causa:** No has configurado la variable `DBT_ENVIRONMENTS` en tu profile.
El valor por defecto del proyecto es `FAIL` precisamente para detectar este
error rápido.

**Solución:** Ve a tu profile de dbt Cloud y añade `DBT_ENVIRONMENTS=ALUMNOX_DEV`.

### ❌ `Compilation Error: macro 'obtener_valores' could not be found`

**Causa:** Has olvidado ejecutar `dbt deps`.

**Solución:**
```bash
dbt deps
```

### ❌ `Snapshot 'users_snapshot_timestamp' has no rows to insert`

**Causa:** No tienes datos en `<ALUMNOX>_DEV_BRONZE_DB.sql_server_dbo.users`.

**Solución:** Asegúrate de que tu Bronze está poblada (los datos los provee
el curso, deben haberse cargado al inicio).

### ❌ `Database error: Object 'WH_CURSO_DATA_ENGINEERING' does not exist or not authorized`

**Causa:** Tu rol `CURSO_DATA_ENGINEERING` no tiene permisos USAGE sobre el
warehouse, o el warehouse está suspendido y tu cuenta no puede reanudarlo.

**Solución:** Pide al instructor que te dé permisos `USAGE` y `OPERATE` sobre
el warehouse.

### ❌ Los modelos se crean en el schema `dbt_alumnox_core` en lugar de `core`

**Causa:** El macro custom `generate_schema_name.sql` no está siendo aplicado.

**Solución:** Verifica que `DBT_ENVIRONMENTS` está bien configurada. En DEV
verás `dbt_alumnox` (porque queremos aislar tu trabajo del de los demás);
en PRO verás `core`, `staging`, ... directamente.

### ❌ Un modelo incremental sigue ejecutándose como tabla completa

**Causa:** Probablemente estás ejecutando con `--full-refresh` o es la primera
ejecución (la tabla aún no existe).

**Solución:** Ejecuta sin `--full-refresh`. Solo en la PRIMERA ejecución
construye la tabla completa; en las siguientes solo procesa filas nuevas.

---

## 📚 Recursos adicionales

- [Documentación oficial de dbt](https://docs.getdbt.com/)
- [dbt Hub (paquetes)](https://hub.getdbt.com/)
- [dbt Best Practices](https://docs.getdbt.com/best-practices)
- [dbt-utils macros reference](https://github.com/dbt-labs/dbt-utils)

---

**Autor**: Equipo Cívica Software · Curso de Data Engineering
