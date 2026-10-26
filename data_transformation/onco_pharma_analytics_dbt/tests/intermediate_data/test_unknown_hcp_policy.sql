{{ config(tags=['p1','unknown_member'], severity='error') }}

-- Enforce policy: populated HCP NPI must resolve to an HCP SK in patient-unit intermediate data.
-- If your approved policy permits unresolved HCPs, disable this test and use an exception/unknown-member policy instead.

SELECT 
    source_transaction_id, 
    unit_source, 
    hcp_npi
FROM {{ ref('idl_ptnt_txn_units') }}
WHERE hcp_npi IS NOT NULL 
    AND dim_hcp_sk IS NULL
