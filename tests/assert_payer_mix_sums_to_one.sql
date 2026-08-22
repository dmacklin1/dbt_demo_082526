-- Payer mix is the weighting behind every discount calculation. If a segment
-- fails to load, the mix no longer sums to 1.0 and the blended discount is
-- silently understated — which would overstate net sales without any error.

select
    access_week,
    sum(payer_mix) as total_payer_mix

from {{ ref('stg_mmit__market_access') }}

group by access_week
having abs(sum(payer_mix) - 1) > 0.001
