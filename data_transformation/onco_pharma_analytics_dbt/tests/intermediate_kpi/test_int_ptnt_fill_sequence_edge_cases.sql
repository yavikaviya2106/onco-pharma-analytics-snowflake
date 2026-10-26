{{ config(tags=['p1','kpi_edge'], severity='error') }}

SELECT 
    source_transaction_id, 
    unit_source, 
    patient_id
FROM {{ ref('int_ptnt_fills') }}

WHERE (fill_number=1 AND (fill_type <> 'INITIAL' OR NOT COALESCE(initial_fill_flag,FALSE)))
 OR (fill_number>1 AND (fill_type <> 'REFILL' OR NOT COALESCE(refill_flag,FALSE)))
 OR (previous_fill_date IS NULL AND days_between_fills IS NOT NULL)
 OR (previous_fill_date IS NOT NULL AND days_between_fills <> DATEDIFF(day,previous_fill_date,fill_date))
 OR (COALESCE(therapy_gap_days,0)=0 AND COALESCE(therapy_gap_flag,FALSE))
 OR (COALESCE(therapy_gap_days,0)>0 AND NOT COALESCE(therapy_gap_flag,FALSE))
 OR (COALESCE(gap_90_flag,FALSE) AND NOT COALESCE(gap_60_flag,FALSE))
 OR (COALESCE(gap_60_flag,FALSE) AND NOT COALESCE(gap_30_flag,FALSE))
