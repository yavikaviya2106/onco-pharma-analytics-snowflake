{{ config(severity='error', tags=['quality_gate','p0']) }}

WITH expected AS (
    SELECT 
        hub_pap_transaction_id AS id, 
        quantity_dispensed AS qty 
    FROM {{ ref('fct_hub_transactions') }} 
    WHERE UPPER(transaction_status)='COMPLETED' 
        AND quantity_dispensed>0 AND shipment_date IS NOT NULL
),

actual AS (
    SELECT 
        source_transaction_id AS id, 
        units_dispensed AS qty 
    FROM {{ ref('idl_ptnt_txn_units') }} 
    WHERE unit_source='PAP'
)

SELECT 
    COALESCE(e.id,a.id) AS id, 
    e.qty AS expected_qty,
    a.qty AS actual_qty

FROM expected e 
FULL OUTER JOIN actual a 
    ON e.id=a.id
WHERE e.id IS NULL 
    OR a.id IS NULL OR e.qty<>a.qty
