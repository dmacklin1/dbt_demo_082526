{{
    config(
        materialized = 'table'
    )
}}

-- Field force execution, territory by week. Veeva and internal reference data
-- only — no financial or syndicated inputs.
--
-- Because every upstream source of this model refreshes daily, this fact and
-- the dashboard built on it stay healthy even when the finance and syndicated
-- feeds are behind. That contrast is the point.

with calls as (

    select * from {{ ref('int_calls__territory_week') }}

),

geography as (

    select * from {{ ref('stg_internal__geography') }}

),

calendar as (

    select * from {{ ref('stg_internal__calendar') }}

),

rep as (

    select * from {{ ref('stg_veeva__rep') }}

),

final as (

    select
        calls.call_week,
        calls.territory_id,
        rep.rep_id,

        geography.territory_name,
        geography.area_name,
        geography.region_name,

        calendar.cycle_id,
        calendar.selling_days,

        calls.calls_planned,
        calls.calls_completed,
        calls.hcps_reached,
        calls.hcps_targeted,
        calls.calls_in_person,
        calls.calls_tier_1,

        -- Call plan attainment: did the rep make the calls they committed to.
        div0(calls.calls_completed, calls.calls_planned)        as call_plan_attainment,

        -- Reach: share of the target list actually seen this week.
        div0(calls.hcps_reached, calls.hcps_targeted)           as reach_pct,

        -- Frequency: average completed calls per HCP actually reached.
        div0(calls.calls_completed, calls.hcps_reached)         as frequency,

        div0(calls.calls_completed, calendar.selling_days)      as calls_per_selling_day

    from calls
    left join geography on calls.territory_id = geography.territory_id
    left join calendar  on calls.call_week    = calendar.calendar_week
    left join rep       on calls.territory_id = rep.territory_id

)

select * from final
