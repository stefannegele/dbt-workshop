# dbt-workshop

dbt project to prepare an internal dbt workshop (audience: Oracle/PL-SQL team moving to
Snowflake). Builds a star schema from the TPC-H practice dataset
(`analytics.tpch_workshop`) across the staging → intermediate → marts layers.

## Environment

- Project name: `dbt_workshop`, profile: `dbt_workshop` (in `~/.dbt/profiles.yml`, not in the repo)
- Target schema for local development: `analytics.dbt_sn`
- Source: `analytics.tpch_workshop` (`customer`, `orders`, `lineitem`, `part`, `supplier`, `nation`, `region`)
- Python venv under `.venv/` (`uv venv --python 3.12` — Fusion/dbt-core need Python ≤3.12, system Python is newer)
- Auth: Snowflake key pair, PKCS#8 (no password, no SSO — the account has no SAML federation configured)
- Local engine: **dbt Fusion** (Rust engine, preview CLI, package name `dbt` via `pip install --pre dbt`
  in `.venv/`). Same engine that will later run natively in **Snowflake Workspaces**
  (dbt Projects on Snowflake) for the workshop — usable here locally for prep/debugging, including
  faster compile-time error checking. Reads `profiles.yml`/`dbt_project.yml` unchanged, no separate
  dbt-core adapter needed.
- `docs/` is deliberately gitignored (workshop prep material, not public)

## Model layer rules

- **Staging** (`stg_`) — exactly one source, `{{ source() }}`, only rename/cast/lightly clean.
  **No joins, no business logic.** Materialization: `view`.
- **Intermediate** (`int_`) — joins staging models via `{{ ref() }}`, encapsulates business logic
  and aggregation, deliberately chooses the grain. Not for end users. Materialization: `view`.
- **Marts** (`fct_`, `dim_`) — finished, business-ready facts & dimensions. The only layer that
  BI (Qlik) reads. Materialization: `table`.
- Always use `{{ ref() }}` / `{{ source() }}`, never hardcode table names.

## Reuse

- Result needed in multiple places → build as a model, reference via `{{ ref() }}`
  (e.g. `net_amount` lives once in `int_line_items_enriched`).
- Same formula on different columns → macro (e.g. `macros/net_amount.sql`).
- **Rule of Three:** don't extract into a macro prematurely — only once the same logic shows up
  a third time. Readable SQL beats clever Jinja.

## Grain trap

Joins at the intermediate layer can multiply row counts (fan-out). `dbt run` only checks that the
SQL runs — not that the result is correct. That's why we test against the actual grain:
`int_line_items_enriched`/`fct_line_items` are unique on (`order_id`, `line_number`), not on
`order_id` alone.

## Tests & docs

Every model has at least `not_null`/`unique` on its primary key; FKs get `relationships` tests
against the respective dimension/staging source. Descriptions live in the accompanying `_*.yml`
files per folder.

## Commands

```bash
.venv/bin/dbt debug
.venv/bin/dbt deps
.venv/bin/dbt build
.venv/bin/dbt build --select <model>+   # targeted development
```
