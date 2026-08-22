# Build order

## 0. Before anything — set the clock

In the R script change `today_date <- as.Date("2026-08-19")` to:

```r
today_date <- Sys.Date()
```

`INSERT_TIME` is generated relative to `today_date`. If you load data today and
demo in five days, the Veeva feed drifts from FRESH to ERROR and the whole
freshness story inverts. **Re-run the R script and reload the CSVs the day
before the interview.**

## 1. R

Paste `R_INSERT_TIME_patch.R` immediately before the `--- EXPORTS ---` block.
It prints a summary table of `MAX(INSERT_TIME)` per table — check it against the
expected outcome below before exporting.

## 2. Load to Snowflake

All nine CSVs into `DBT_DEMO_BRZ.SOURCE_A`. Then confirm the column casing:

```sql
select * from DBT_DEMO_BRZ.SOURCE_A.F_SALES limit 5;
```

If the Snowflake loader created quoted mixed-case identifiers (`"Territory_ID"`)
rather than uppercase, the staging models will fail. Fix by reloading with
`MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE`, or add quoted identifiers to the
staging SQL. Uppercase unquoted is what these models assume.

## 3. dbt

```bash
dbt deps          # dbt_utils, required by several tests
dbt debug
dbt source freshness   # <-- run this FIRST, see below
dbt build
dbt docs generate
```

**`dbt source freshness` is your canary.** Expected result:

| Source | Table | Expected |
|---|---|---|
| veeva | f_calls | PASS |
| veeva | d_rep | PASS |
| veeva | d_hcp | *not configured* (commented out — enable live) |
| mmit | f_market_access | PASS |
| sap | f_sales | **WARN** |
| sap | f_demand | **WARN** |
| iqvia | f_market_share | **ERROR** |
| internal | d_geography, d_calendar | *not configured* (static by design) |

If everything passes, `loaded_at_field` isn't resolving — check that
`INSERT_TIME` landed as a timestamp and not as text.

Note: `dbt source freshness` exits non-zero when a source errors. That is the
correct outcome here, not a failure of your setup.

## 4. Job configuration

One production deploy job, in a deployment environment marked **Production**:

- Tick **Run source freshness** in Execution Settings (runs first, does not
  block later steps — you want a red source *and* a completed build)
- Tick **Generate docs on run**
- Run step: `dbt build`

Catalog needs `dbt build` + `dbt docs generate` + `dbt source freshness` in the
same job to populate fully. CI jobs never update Catalog. Run the job three or
four times across your prep days so you have real run history and model timing.

## 5. Health tiles

Catalog → Exposures → pick an exposure → Data health → expand the embed toggle.
Requires a **Metadata Only** service token (Account settings → API tokens).
Both exposures are already `type: dashboard`, which is required for the embed
dropdown to appear at all.

Paste the two iFrame snippets into `dashboard_mock.html` and open it as a local
file. That is your "embedded in a BI tool" visual — no Tableau needed.

## 6. Deliberate gaps, for the live demo

| Where | What's missing | Use it for |
|---|---|---|
| `_sources_veeva.yml` | freshness on `d_hcp` is commented out | Enable it live — closing a monitoring gap in 30 seconds |
| `_stg_dims.yml` | `stg_veeva__hcp` has no descriptions | dbt Wizard doc generation, and the `tier` example |
| `_stg_facts.yml` | `stg_iqvia__market_share` has no descriptions | Backup Wizard target if the first one misbehaves |

Leave these broken. They are the demo.
