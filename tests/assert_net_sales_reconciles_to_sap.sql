-- The gold layer recomputes net sales from the MMIT payer mix rather than
-- accepting SAP's figure. This test proves the two agree, which is what makes
-- the recomputation safe to report on.
--
-- Any territory-week where the recomputed value drifts more than a dollar from
-- SAP's own calculation is returned as a failure.

select
    sales_week,
    territory_id,
    net_sales,
    net_sales_sap,
    abs(net_sales - net_sales_sap) as variance

from {{ ref('fct_territory_performance') }}

where net_sales_sap is not null
  and abs(net_sales - net_sales_sap) > 1
