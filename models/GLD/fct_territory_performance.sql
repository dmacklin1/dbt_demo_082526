{{ config(materialized = 'table') }}

-- Territory commercial performance by week: volume, gross-to-net, goal
-- attainment, competitive context, and the field activity behind it.
--
-- net_sales is RECOMPUTED here rather than passed through from SAP. Gross sales
-- come from the finance system; the discount applied to them comes from the MMIT
-- payer mix. Two source systems, two owners, two refresh cadences, one number on
-- the dashboard.

with sales as (

    select * from {{ ref('stg_sap__sales') }}

),

demand as (

    select * from {{ ref('stg_sap__demand') }}

),

market_access as (

    select * from {{ ref('stg_mmit__market_access') }}

),

market_share as (

    select * from {{ ref('stg_iqvia__market_share') }}

),

calls as (

    select * from {{ ref('stg_veeva__calls') }}

),

hcp as (

    select * from {{ ref('stg_veeva__hcp') }}

),

geography as (

    select * from {{ ref('stg_internal__geography') }}

),

calendar as (

    select * from {{ ref('stg_internal__calendar') }}

),

-- Collapse the four payer segments into one blended rate by weighting each
-- segment's negotiated discount by its share of national volume.
blended_discount as (

    select
        access_week,
        sum(segment_discount * payer_mix)   as blended_discount_rate,
        count(distinct payer_segment)       as segments_contributing

    from market_access
    group by 1

),

-- National brand share, rolled to month across both indications.
brand_share as (

    select
        date_trunc('month', share_month_end)                        as share_month,
        div0(
            sum(case when is_our_brand then trx_volume else 0 end),
            sum(trx_volume)
        )                                                           as brand_trx_share,
        sum(trx_volume)                                             as market_trx_total

    from market_share
    group by 1

),

-- Aggregate to territory-week before joining, to protect the grain.
calls_by_territory_week as (

    select
        calls.call_week,
        calls.territory_id,
        sum(calls.completed_call_flag)                      as calls_completed,
        count(distinct case when calls.completed_call_flag = 1
                            then calls.hcp_id end)          as hcps_reached,
        count(distinct case when hcp.is_targeted
                            then calls.hcp_id end)          as hcps_targeted

    from calls
    left join hcp
        on calls.hcp_id = hcp.hcp_id
    group by 1, 2

),

final as (

    select
        s.sales_week,
        s.territory_id,

        g.territory_name,
        g.area_name,
        g.region_name,
        cal.cycle_id,

        -- ---- Volume, from SAP -------------------------------------------
        d.trx_actual,
        d.nbrx_actual,
        d.nbrx_forecast,

        -- ---- Gross to net -----------------------------------------------
        s.gross_sales,

        -- The discount rate is an MMIT input, not a finance input.
        bd.blended_discount_rate,

        s.gross_sales * bd.blended_discount_rate            as revenue_deduction,

        s.gross_sales
            - (s.gross_sales * bd.blended_discount_rate)    as net_sales,

        -- ---- Goal attainment -----------------------------------------------
        s.net_sales_goal,

        div0(
            s.gross_sales - (s.gross_sales * bd.blended_discount_rate),
            s.net_sales_goal
        )                                                   as goal_attainment_pct,

        -- ---- Competitive context, from IQVIA --------------------------------
        bs.brand_trx_share,
        bs.market_trx_total,

        -- ---- Field activity context -----------------------------------------
        c.calls_completed,
        c.hcps_reached,
        div0(c.hcps_reached, c.hcps_targeted)               as reach_pct,

        -- ---- Reconciliation only ---------------------------------------------
        s.net_sales_sap

    from sales s
    left join demand d
        on  s.sales_week   = d.demand_week
        and s.territory_id = d.territory_id
    left join blended_discount bd
        on  s.sales_week   = bd.access_week
    left join brand_share bs
        on  date_trunc('month', s.sales_week) = bs.share_month
    left join calls_by_territory_week c
        on  s.sales_week   = c.call_week
        and s.territory_id = c.territory_id
    left join geography g
        on  s.territory_id = g.territory_id
    left join calendar cal
        on  s.sales_week   = cal.calendar_week

)

select * from final
