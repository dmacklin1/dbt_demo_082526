with source as (

    select * from {{ source('iqvia', 'f_market_share') }}

),

renamed as (

    select
        cast(date as date)          as share_month_end,
        company_drug_name           as drug_name,
        indication,
        trx_volume,
        trx_share,
        case when company_drug_name = 'TargetBrand' then true else false end
                                    as is_our_brand,
        insert_time                 as loaded_at

    from source

)

select * from renamed
