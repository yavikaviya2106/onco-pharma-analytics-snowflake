SELECT 
    ddd_record_id 
FROM {{ ref('fct_pdt_distribution') }} 
WHERE sales_units < 0 OR returns_units < 0 OR standard_units < 0 OR package_units < 0
