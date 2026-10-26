SELECT 
    xponent_record_id 
FROM {{ ref('fct_rx_sales') }} 
WHERE trx < 0 OR nrx < 0 OR nbrx < 0 
    OR refill_rx < 0 
    OR nrx > trx 
    OR nbrx > nrx 
    OR refill_rx > trx
