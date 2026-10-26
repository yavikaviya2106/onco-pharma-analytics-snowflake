{{ config(severity='error', tags=['quality_gate','p0']) }}

SELECT * FROM {{ ref('agg_territory_performance') }}
WHERE (hcp_reach_rate IS NOT NULL 
    AND (hcp_reach_rate < 0 OR hcp_reach_rate > 1)) 
    OR (target_hcp_reach_rate IS NOT NULL 
    AND (target_hcp_reach_rate < 0 OR target_hcp_reach_rate > 1)) 
    OR (writer_rate IS NOT NULL AND (writer_rate < 0 OR writer_rate > 1)) 
    OR (trx_market_share IS NOT NULL AND (trx_market_share < 0 OR trx_market_share > 1)) 
    OR (nrx_market_share IS NOT NULL AND (nrx_market_share < 0 OR nrx_market_share > 1))
