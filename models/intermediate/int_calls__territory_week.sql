{{
    config(
        materialized = 'view'
    )
}}

-- Aggregates individual call records up to the territory-week grain so that
-- downstream facts can join to sales and demand without fanning out.
--
-- Reach and frequency are defined here, once, rather than being redefined in
-- every dashboard that needs them.

with calls as (

    select * from {{ ref('stg_veeva__calls') }}

),

hcp as (

    select * from {{ ref('stg_veeva__hcp') }}

),

joined as (

    select
        calls.call_week,
        calls.territory_id,
        calls.hcp_id,
        calls.call_id,
        calls.indication,
        calls.call_type,
        calls.planned_call_flag,
        calls.completed_call_flag,
        hcp.tier,
        hcp.is_targeted

    from calls
    left join hcp
        on calls.hcp_id = hcp.hcp_id

),

aggregated as (

    select
        call_week,
        territory_id,

        sum(planned_call_flag)                              as calls_planned,
        sum(completed_call_flag)                            as calls_completed,

        count(distinct case when completed_call_flag = 1
                            then hcp_id end)                as hcps_reached,
        count(distinct case when is_targeted
                            then hcp_id end)                as hcps_targeted,

        sum(case when call_type = 'In-Person'
                 then completed_call_flag else 0 end)       as calls_in_person,
        sum(case when indication = 'Derm'
                 then completed_call_flag else 0 end)       as calls_derm,
        sum(case when tier = 'T1'
                 then completed_call_flag else 0 end)       as calls_tier_1

    from joined
    group by 1, 2

)

select * from aggregated
