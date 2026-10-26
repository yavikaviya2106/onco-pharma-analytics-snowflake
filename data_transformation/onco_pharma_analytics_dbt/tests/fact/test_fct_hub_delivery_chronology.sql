SELECT 
    hub_pap_transaction_id 
FROM {{ ref('fct_hub_transactions') }} 
WHERE (shipment_date IS NOT NULL 
    AND shipment_date < transaction_date) 
    OR (delivery_date IS NOT NULL AND shipment_date IS NOT NULL AND delivery_date < shipment_date)
