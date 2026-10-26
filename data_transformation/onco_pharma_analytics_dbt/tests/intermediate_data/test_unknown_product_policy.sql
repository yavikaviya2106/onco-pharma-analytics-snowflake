{{ config(tags=['p1','unknown_member'], severity='error') }}

SELECT 
    source_transaction_id, 
    unit_source, 
    product_id
FROM {{ ref('idl_ptnt_txn_units') }}
WHERE product_id IS NOT NULL AND dim_prod_sk IS NULL
