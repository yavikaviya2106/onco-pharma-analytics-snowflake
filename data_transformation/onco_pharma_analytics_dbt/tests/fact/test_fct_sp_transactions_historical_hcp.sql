{{ config(severity='error', tags=['quality_gate','p0']) }}

SELECT
    f.hcp_npi,
    f.transaction_date,
    f.dim_hcp_sk,
    COUNT(DISTINCT h.dim_hcp_sk) AS matching_versions,
    MIN(h.dim_hcp_sk)            AS matched_sk
FROM {{ ref('fct_sp_transactions') }} f
LEFT JOIN {{ ref('dim_hcp_master') }} h
    ON  f.hcp_npi = h.hcp_npi
    AND f.transaction_date >= h.valid_from
    AND (f.transaction_date < h.valid_to OR h.valid_to IS NULL)
WHERE f.hcp_npi IS NOT NULL
  AND f.transaction_date IS NOT NULL
GROUP BY
    f.hcp_npi,
    f.transaction_date,
    f.dim_hcp_sk
HAVING COUNT(DISTINCT h.dim_hcp_sk) <> 1   -- 0 = orphan, >1 = overlapping SCD2 windows
    OR MIN(h.dim_hcp_sk) <> f.dim_hcp_sk   -- fact points to the wrong version