{{ config(severity='error', tags=['quality_gate','p0']) }}

SELECT * FROM {{ ref('agg_prod_mvmt_dtl') }} 
WHERE ABS(COALESCE(net_units,0) - (COALESCE(gross_sales_units,0) - COALESCE(returns_units,0)))>0.00001
