with source as (

    select * from {{ source('internal', 'd_geography') }}

),

renamed as (

    select
        territory_id,
        territory_name,
        area_id,
        area_name,
        region_id,
        region_name,
        nation,
        insert_time                 as loaded_at

    from source

)

select * from renamed
