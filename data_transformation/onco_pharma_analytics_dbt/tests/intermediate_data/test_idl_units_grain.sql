{{ config(severity='error', tags=['quality_gate','p0']) }}

SELECT 
    unit_source,
    source_transaction_id,
    COUNT(*) AS row_count 
FROM {{ ref('idl_ptnt_txn_units') }} 
GROUP BY 1,2 
HAVING COUNT(*) <> 1
