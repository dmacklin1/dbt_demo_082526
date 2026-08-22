with source as (

    select * from {{ source('sap', 'f_sales') }}

),

renamed as (

    select
        cast(date as date)              as sales_week,
        territory_id,
        gross_sales,
        net_sales_goals                 as net_sales_goal,

        -- Retained for reconciliation against the recomputed figure in gold.
        net_sales                       as net_sales_sap,
        revenue_deduction               as revenue_deduction_sap,

        insert_time                     as loaded_at

    from source

)

select * from renamed
