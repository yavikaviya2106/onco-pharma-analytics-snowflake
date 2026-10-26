{{ config(tags=['p1','temporal'], severity='error') }}

WITH expected AS (
    SELECT 
        source_transaction_id, 
        unit_source, 
        patient_id, 
        dim_prod_sk,
        MIN(shipment_date) OVER (PARTITION BY patient_id, dim_prod_sk) AS first_fill_date,
        MAX(shipment_date) OVER (PARTITION BY patient_id, dim_prod_sk) AS last_fill_date
    FROM {{ ref('idl_ptnt_txn_units') }} 
    WHERE shipment_date IS NOT NULL
)


SELECT 
    f.source_transaction_id, 
    f.unit_source, 
    f.patient_id, 
    f.dim_prod_sk
FROM {{ ref('int_ptnt_fills') }} f
JOIN expected e 
    ON f.source_transaction_id=e.source_transaction_id
    AND f.unit_source=e.unit_source
WHERE f.fill_date < e.first_fill_date OR f.fill_date > e.last_fill_date
 OR f.initial_fill_date <> e.first_fill_date OR f.last_fill_date <> e.last_fill_date
 OR f.coverage_end_date <> DATEADD(day, f.days_supply-1, f.fill_date)
