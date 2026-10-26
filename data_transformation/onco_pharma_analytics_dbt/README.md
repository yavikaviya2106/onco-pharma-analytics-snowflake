# onco_pharma_analytics_dbt 

A dbt project that transforms raw US oncology commercial data in Snowflake into conformed dimensions, facts, patient-journey tables and HCP/territory KPI aggregates.

> **Status:** `dbt deps` and `dbt parse` were verified (dbt-core 1.12.6, dbt-snowflake 1.12.3). `dbt build/test` have not been run against a warehouse, so model results and test outcomes are not yet observed.

## Purpose

The **T** in an ELT pipeline. dbt reads 28 raw tables from `ONCO_PHARMA_DATA` (loaded upstream by the Python/Airflow ingestion in the repo root) and builds all downstream models inside Snowflake. Airflow runs the project for two targets from the same code:

| Target | Output database.schema |
|---|---|
| `dev` | `ONCO_PHARMA_ANALYTICS.DEV` |
| `prd` | `ONCO_PHARMA_COMMERCIAL.PRD` |

## Data Sources (8 sources, 28 tables)

Industry-standard commercial pharma systems: **IQVIA** (Xponent, DDD, OneKey), **Veeva** (CRM, Align), **Hub** and **Specialty Pharmacy** transactions, plus internal and product MDM (brands, SKUs, field force, call plans, target lists).

## Architecture

```
raw sources → landing → staging → snapshots (SCD2) → dimension / bridge → fact → intermediate → aggregate
```

| Layer | Models | Materialization | Role |
|---|---|---|---|
| Landing `raw_` | 28 | view | One `SELECT *` per source table |
| Staging `stg_` | 28 | view | Cleaning, type casting, standardizing flags/NPI/NDC |
| Dimension `dim_` | 17 | table / incremental | Conformed dimensions, SCD2 masters (HCP, HCO, address, field force, territory), product hierarchy, date and time buckets |
| Bridge `bridge_` | 3 | view | HCP–HCO affiliation, rep–territory, ZIP–territory |
| Fact `fct_` | 12 | incremental (merge) | Calls, emails, events, samples, hub/SP transactions, Rx sales, distribution |
| Intermediate `idl_` / `int_` | 7 / 10 | view / table | Unified touchpoints, patient cases and journeys, period-bucketed HCP and patient metrics |
| Aggregate `agg_` | 5 | table | Final HCP, territory, patient-journey and product-movement tables |

**Total: 110 models + 6 snapshots.**

## Key Design Decisions

- **History tracking:** 6 timestamp-based snapshots (HCP, HCO, address, field force, territory, ZIP-to-territory) feed SCD2 dimensions with `valid_from` / `valid_to`.
- **Incremental loads:** all facts and 5 dimensions merge on a unique key, reprocessing a 1-day lookback window.
- **Patient journey logic:** therapy status is driven by configurable variables (`therapy_gap_days`, default 30; `data_as_of_date`).
- **Reporting calendar:** date spine from 2021 to 2031 with Saturday–Friday weeks, matching IQVIA weekly reporting.
- **Timezone:** audit timestamps use IST via a shared macro.
- **Fail fast:** the run stops at the first failure.

## Data Quality

**204 tests** resolved at parse time:

- **Generic (161):** `not_null`, `unique`, `relationships`, `accepted_values`, plus `dbt_utils` combination and expression checks.
- **Singular (43 enabled):** SCD2 range/overlap checks, fact-to-staging reconciliation, chronology and non-negative checks, unit-allocation and grain checks.
- **Disabled by default (2):** source freshness control and approved-baseline comparison; both need external audit/baseline tables.

## Configuration

Uses a project-level `profiles.yml` driven entirely by environment variables (Snowflake account, user, role, warehouse and per-target database). No secrets are committed. Dependencies: `dbt_utils` (`>=1.1.0,<2.0.0`).

## Known Limitations

- No model/column descriptions in YAML, so `dbt docs` shows structure and lineage only.
- No source freshness checks or source tests.
- `threads: 1` on both targets, so large IQVIA builds are slow.
- Source database name is hard-coded in `sources.yml`.
- Docker image installs an unpinned `dbt-snowflake`, which may differ from `uv.lock`.
- Build and test results have not been verified end to end.


### Resources:
- Learn more about dbt [in the docs](https://docs.getdbt.com/docs/introduction)
- Check out [Discourse](https://discourse.getdbt.com/) for commonly asked questions and answers
- Join the [chat](https://community.getdbt.com/) on Slack for live discussions and support
- Find [dbt events](https://events.getdbt.com) near you
- Check out [the blog](https://blog.getdbt.com/) for the latest news on dbt's development and best practices
