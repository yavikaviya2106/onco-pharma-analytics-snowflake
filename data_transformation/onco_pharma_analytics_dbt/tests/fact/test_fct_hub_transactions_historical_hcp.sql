{{ config(severity='error', tags=['quality_gate','p0']) }}

-- Each transaction must match exactly ONE HCP version, and it must be the one stored in the fact.
-- Grouped per transaction (not per npi + date), so two transactions on the same
-- day for the same HCP are not counted as two versions.
SELECT
    f.hub_pap_transaction_id,
    f.hcp_npi,
    f.transaction_date,
    f.dim_hcp_sk,
    COUNT(DISTINCT h.dim_hcp_sk) AS matching_versions
FROM {{ ref('fct_hub_transactions') }} f

LEFT JOIN {{ ref('dim_hcp_master') }} h
    ON f.hcp_npi = h.hcp_npi
    AND f.transaction_date >= h.valid_from
    AND (f.transaction_date < h.valid_to OR h.valid_to IS NULL)

WHERE f.hcp_npi IS NOT NULL
  AND f.transaction_date IS NOT NULL
GROUP BY
    f.hub_pap_transaction_id,
    f.hcp_npi,
    f.transaction_date,
    f.dim_hcp_sk
HAVING COUNT(DISTINCT h.dim_hcp_sk) <> 1
    OR MAX(h.dim_hcp_sk) <> f.dim_hcp_sk