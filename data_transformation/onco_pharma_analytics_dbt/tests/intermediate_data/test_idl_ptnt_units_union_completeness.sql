WITH expected AS (
    SELECT 
        'PAP' AS unit_source, 
        hub_pap_transaction_id AS source_transaction_id 
    FROM {{ ref('fct_hub_transactions') }} 
    WHERE UPPER(transaction_status) = 'COMPLETED' 
        AND quantity_dispensed > 0 
        AND shipment_date IS NOT NULL 
        
    UNION ALL 
    
    SELECT 
        'SP' AS unit_source, 
        sp_transaction_id AS source_transaction_id
    FROM {{ ref('fct_sp_transactions') }} 
    WHERE UPPER(transaction_status) IN ('CLOSED - DELIVERED','IN PROGRESS - SHIPPED') 
        AND quantity_dispensed > 0 
        AND shipment_date IS NOT NULL
), 

actual AS (
    SELECT 
        unit_source, 
        source_transaction_id 
    FROM {{ ref('idl_ptnt_txn_units') }}
) 

SELECT 
    'missing' AS issue, 
     e.unit_source, 
     e.source_transaction_id 
FROM expected e 
LEFT JOIN actual a 
    ON e.unit_source=a.unit_source 
    AND e.source_transaction_id = a.source_transaction_id 
    
WHERE a.source_transaction_id IS NULL 

UNION ALL 

SELECT 
    'unexpected' AS issue, 
    a.unit_source,
    a.source_transaction_id 
FROM actual a 
LEFT JOIN expected e 
    ON e.unit_source=a.unit_source 
    AND e.source_transaction_id=a.source_transaction_id 

WHERE e.source_transaction_id IS NULL
