with source as (

    select * from {{ source('internal', 'd_calendar') }}

),

renamed as (

    select
        cast(date as date)          as calendar_week,
        year                        as calendar_year,
        cycle_id,
        business_days_week          as selling_days,
        insert_time                 as loaded_at

    from source

)

select * from renamed
