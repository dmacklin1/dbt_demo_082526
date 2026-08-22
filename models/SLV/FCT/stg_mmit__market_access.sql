with source as (

    select * from {{ source('mmit', 'f_market_access') }}

),

renamed as (

    select
        cast(date as date)          as access_week,
        segment                     as payer_segment,
        segment_discount,
        payer_mix,
        insert_time                 as loaded_at

    from source

)

select * from renamed
