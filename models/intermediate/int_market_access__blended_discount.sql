{{
    config(
        materialized = 'view'
    )
}}

-- Collapses the four payer segments into a single blended discount rate by
-- weighting each segment's negotiated discount by its share of national volume.
--
-- This model is the reason net_sales has two upstream source systems. The
-- volume half of net sales comes from SAP; the discount half arrives here,
-- from MMIT.

with market_access as (

    select * from {{ ref('stg_mmit__market_access') }}

),

blended as (

    select
        access_week,
        sum(segment_discount * payer_mix)   as blended_discount_rate,
        count(distinct payer_segment)       as segments_contributing

    from market_access
    group by 1

)

select * from blended
