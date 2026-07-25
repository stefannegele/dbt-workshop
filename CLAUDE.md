# dbt-workshop

dbt project to prepare an internal dbt workshop (audience: Oracle/PL-SQL team moving to
Snowflake). Builds a star schema from the TPC-H practice dataset
(`analytics.tpch_workshop`) across the staging → intermediate → marts layers.

## Environment

- Project name: `dbt_workshop`, profile: `dbt_workshop`
- Target schema: `analytics.dbt_sn`
- **Two `profiles.yml` files exist, for two different execution contexts:**
  - `~/.dbt/profiles.yml` (local machine, **not** in the repo) — real key-pair auth, used by the
    local venv/CLI below.
  - `profiles.yml` (repo root, **committed**) — used by **dbt Projects on Snowflake** when this
    repo is imported/run inside Snowflake (Workspaces or `EXECUTE DBT PROJECT`). Snowflake requires
    this file to be present in the project folder to know which warehouse/database/schema/role to
    target. It's safe to commit: `account`/`user` are placeholder strings ("not needed") — execution
    runs under the current Snowflake session's account/user context, not via these fields.
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

Two test types, matching the workshop's Part 4:

- **Generic tests (YAML)** — column-level constraints and fixed relationships between two models:
  `not_null`, `unique`, `relationships`, `accepted_values`, plus package tests like
  `dbt_utils.unique_combination_of_columns`, `dbt_utils.accepted_range`, `dbt_utils.equal_rowcount`.
  Declared in the `_*.yml` files next to each layer's models. Every model has at least
  `not_null`/`unique` on its primary key; FKs get `relationships` tests against the respective
  dimension/staging source.
- **Singular tests (SQL)** — one-off `.sql` files under `tests/` for checks a generic test can't
  express: aggregation across rows, business-formula reconciliation, gap detection. A query that
  returns rows on failure, empty on success.
- Before writing a singular test, check whether a generic/package test already covers it (e.g.
  `dbt_utils.equal_rowcount` instead of a hand-rolled row-count comparison) — same
  reuse-before-rebuild principle as the `net_amount` macro.
- **`net_amount` is tax-exclusive by design; `order_total` (TPC-H `o_totalprice`) isn't.**
  `stg_lineitem.tax` (`l_tax`) exists only to reconcile the two in
  `tests/assert_order_total_matches_line_items.sql`, via the tax-inclusive `charge` formula
  (`extended_price * (1 - discount) * (1 + tax)`) — not to feed `net_amount`/`fct_line_items`.
  That test's tolerance (`> 0.20`) is tuned above the observed floating-point rounding noise from
  summing multiple lines per order (max ~$0.11 across all 1.5M orders); a real defect (e.g. a
  missing tax factor) shows up as a 3-8% gap, ~1000x larger.

Descriptions live in the accompanying `_*.yml` files per folder.

## Snapshots

`snapshots/snap_customers.yml` (Part 5, optional) snapshots `market_segment` as SCD Type 2 —
demonstrates that overwriting a dimension value (Type 1) silently rewrites history for old facts.
Snapshots the **raw source** (`source('tpch', 'customer')`), not `stg_customers`: decouples
snapshot history from staging-logic changes, at the cost of raw column names (`c_custkey`,
`c_mktsegment`) instead of Part 3's renamed ones. Uses the `check` strategy (TPC-H has no
reliable updated-at column) on `c_mktsegment`. `config.schema` is the plain literal
`snapshots`, not `{{ target.schema }}_snapshots` — dbt's default schema-naming already
prepends `target.schema` to any custom schema automatically, so adding it again here would
double-prefix (found the hard way: `dbt_sn_dbt_sn_snapshots`).

## Commands

Both a local `~/.dbt/profiles.yml` and a repo-root `profiles.yml` now exist (see above). dbt looks
in the current directory *before* `~/.dbt/`, so local runs must pin `--profiles-dir ~/.dbt`
explicitly — otherwise dbt picks up the committed repo-root file (no real credentials) and fails.

```bash
.venv/bin/dbt debug --profiles-dir ~/.dbt
.venv/bin/dbt deps  --profiles-dir ~/.dbt
.venv/bin/dbt build --profiles-dir ~/.dbt
.venv/bin/dbt build --profiles-dir ~/.dbt --select <model>+   # targeted development
```
