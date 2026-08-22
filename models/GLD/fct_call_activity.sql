{{ config(materialized = 'table') }}

-- Field force execution by territory and week.
--
-- Every upstream source of this model refreshes daily, so this fact and the
-- dashboard built on it stay healthy even when the finance and syndicated feeds
-- are behind. That contrast is deliberate.

with calls as (

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

rep as (

    select * from {{ ref('stg_veeva__rep') }}

),

-- Aggregate calls from HCP grain up to territory-week before joining anything
-- else, so the joins below cannot fan out the grain.
calls_by_territory_week as (

    select
        calls.call_week,
        calls.territory_id,

        sum(calls.planned_call_flag)                        as calls_planned,
        sum(calls.completed_call_flag)                      as calls_completed,

        count(distinct case when calls.completed_call_flag = 1
                            then calls.hcp_id end)          as hcps_reached,
        count(distinct case when hcp.is_targeted
                            then calls.hcp_id end)          as hcps_targeted,

        sum(case when calls.call_type = 'In-Person'
                 then calls.completed_call_flag else 0 end) as calls_in_person,
        sum(case when hcp.tier = 'T1'
                 then calls.completed_call_flag else 0 end) as calls_tier_1

    from calls
    left join hcp
        on calls.hcp_id = hcp.hcp_id
    group by 1, 2

),

final as (

    select
        c.call_week,
        c.territory_id,
        r.rep_id,

        g.territory_name,
        g.area_name,
        g.region_name,

        cal.cycle_id,
        cal.selling_days,

        c.calls_planned,
        c.calls_completed,
        c.hcps_reached,
        c.hcps_targeted,
        c.calls_in_person,
        c.calls_tier_1,

        div0(c.calls_completed, c.calls_planned)    as call_plan_attainment,
        div0(c.hcps_reached, c.hcps_targeted)       as reach_pct,
        div0(c.calls_completed, c.hcps_reached)     as frequency,
        div0(c.calls_completed, cal.selling_days)   as calls_per_selling_day

    from calls_by_territory_week c
    left join geography g  on c.territory_id = g.territory_id
    left join calendar  cal on c.call_week   = cal.calendar_week
    left join rep       r   on c.territory_id = r.territory_id

)

select * from final
