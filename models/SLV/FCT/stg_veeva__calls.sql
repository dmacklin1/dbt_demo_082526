with source as (

    select * from {{ source('veeva', 'f_calls') }}

),

renamed as (

    select
        call_id,
        cast(date as date)          as call_week,
        hcp_id,
        rep_id,
        territory_id,
        indication,
        call_type,
        call_plan_goal              as planned_call_flag,
        case when call_id is not null then 1 else 0 end
                                    as completed_call_flag,
        insert_time                 as loaded_at

    from source

)

select * from renamed
