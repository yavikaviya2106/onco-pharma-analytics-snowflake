SELECT 
    affiliation_id 
FROM {{ ref('bridge_hcp_hco_affln') }} 
WHERE effective_end_date IS NOT NULL 
    AND effective_end_date <= effective_start_date
