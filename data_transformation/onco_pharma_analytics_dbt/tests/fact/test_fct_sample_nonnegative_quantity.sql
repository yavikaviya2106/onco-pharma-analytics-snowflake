SELECT 
    sample_id FROM {{ ref('fct_sample_disbursed') }} 
WHERE sample_quantity < 0 
    OR return_quantity < 0 
   