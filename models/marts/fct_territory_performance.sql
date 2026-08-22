{{
    config(
        materialized = 'table'
    )
}}

-- Territory commercial performance, week by week. This is the model the
-- executive review runs on.
--
-- Note that net_sales is RECOMPUTED here rather than taken from SAP. Gross
-- sales come from the finance system; the discount applied to them comes from
-- the MMIT payer mix. Two source systems, two owners, two refresh cadences,
-- one number on the dashboard.

with sales as (

    select * from {{ ref('stg_sap__sales') }}

),

demand as (

    select * from {{ ref('stg_sap__demand') }}

),

discount as (

    select * from {{ ref('int_market_access__blended_discount') }}

),

calls as (

    select * from {{ ref('int_calls__territory_week') }}

),

geography as (

    select * from {{ ref('stg_internal__geography') }}

),

calendar as (

    select * from {{ ref('stg_internal__calendar') }}

),

final as (

    select
        sales.sales_week,
        sales.territory_id,

        geography.territory_name,
        geography.area_name,
        geography.region_name,
        calendar.cycle_id,

        -- ---- Volume, from SAP ------------------------------------------
        demand.trx_actual,
        demand.nbrx_actual,
        demand.nbrx_forecast,

        -- ---- Gross to net ----------------------------------------------
        sales.gross_sales,

        -- The discount rate is an MMIT input, not a finance input.
        discount.blended_discount_rate,

        sales.gross_sales * discount.blended_discount_rate
                                                    as revenue_deduction,

        sales.gross_sales
            - (sales.gross_sales * discount.blended_discount_rate)
                                                    as net_sales,

        -- ---- Goal attainment -------------------------------------------
        sales.net_sales_goal,

        div0(
            sales.gross_sales
                - (sales.gross_sales * discount.blended_discount_rate),
            sales.net_sales_goal
        )                                           as goal_attainment_pct,

        -- ---- Field activity context ------------------------------------
        calls.calls_completed,
        calls.hcps_reached,
        div0(calls.hcps_reached, calls.hcps_targeted)
                                                    as reach_pct,

        -- ---- Reconciliation ---------------------------------------------
        sales.net_sales_sap

    from sales
    left join demand
        on  sales.sales_week   = demand.demand_week
        and sales.territory_id = demand.territory_id
    left join discount
        on  sales.sales_week   = discount.access_week
    left join calls
        on  sales.sales_week   = calls.call_week
        and sales.territory_id = calls.territory_id
    left join geography
        on  sales.territory_id = geography.territory_id
    left join calendar
        on  sales.sales_week   = calendar.calendar_week

)

select * from final
