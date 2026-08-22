with source as (

    select * from {{ source('veeva', 'd_hcp') }}

),

renamed as (

    select
        hcp_id,
        tier,
        case when tier in ('T1', 'T2', 'T3') then true else false end
                                        as is_targeted,
        insert_time                     as loaded_at

    from source

)

select * from renamed
