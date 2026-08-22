{{
    config(
        materialized = 'table'
    )
}}

-- Monthly competitive position from syndicated data. Grain is month x drug x
-- indication.
--
-- This model's only upstream source is IQVIA, which is currently months behind.
-- Anything built on it inherits that staleness.

with share as (

    select * from {{ ref('stg_iqvia__market_share') }}

),

with_rank as (

    select
        share_month_end,
        indication,
        drug_name,
        is_our_brand,
        trx_volume,
        trx_share,

        sum(trx_volume) over (
            partition by share_month_end, indication
        )                                                   as market_trx_total,

        rank() over (
            partition by share_month_end, indication
            order by trx_volume desc
        )                                                   as share_rank

    from share

),

final as (

    select
        *,
        trx_share - lag(trx_share) over (
            partition by drug_name, indication
            order by share_month_end
        )                                                   as share_change_mom

    from with_rank

)

select * from final
