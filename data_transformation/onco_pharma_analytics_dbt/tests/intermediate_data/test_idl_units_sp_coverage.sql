{{ config(severity='error', tags=['quality_gate','p0']) }}

WITH expected AS (
    SELECT 
        sp_transaction_id AS id, 
        quantity_dispensed AS qty 
    FROM {{ ref('fct_sp_transactions') }} 
    WHERE UPPER(transaction_status) IN ('CLOSED - DELIVERED','IN PROGRESS - SHIPPED') 
        AND quantity_dispensed>0 AND shipment_date IS NOT NULL
),

actual AS (
    SELECT 
        source_transaction_id AS id, 
        units_dispensed AS qty 
    FROM {{ ref('idl_ptnt_txn_units') }} 
    WHERE unit_source='SP'
)

SELECT 
    COALESCE(e.id,a.id) AS id, 
    e.qty AS expected_qty,
    a.qty AS actual_qty
FROM expected e 
FULL OUTER JOIN actual a
     ON e.id=a.id
WHERE e.id IS NULL OR a.id IS NULL OR e.qty<>a.qty
