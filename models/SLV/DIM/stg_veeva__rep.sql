with source as (

    select * from {{ source('veeva', 'd_rep') }}

),

renamed as (

    select
        rep_id,
        territory_id,
        insert_time                 as loaded_at

    from source

)

select * from renamed
