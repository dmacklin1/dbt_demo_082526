with source as (

    select * from {{ source('sap', 'f_demand') }}

),

renamed as (

    select
        cast(date as date)          as demand_week,
        territory_id,
        trx                         as trx_actual,
        nbrx                        as nbrx_actual,
        nbrx_forecast,
        insert_time                 as loaded_at

    from source

)

select * from renamed
