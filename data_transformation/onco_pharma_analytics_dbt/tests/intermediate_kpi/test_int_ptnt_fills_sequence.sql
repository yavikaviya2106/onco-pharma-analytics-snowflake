SELECT * FROM {{ ref('int_ptnt_fills') }} 
WHERE fill_number < 1 OR channel_fill_number < 1 
    OR (fill_number = 1 AND previous_fill_date IS NOT NULL) 
    OR (previous_fill_date IS NOT NULL AND previous_fill_date > fill_date) 
    OR coverage_end_date < fill_date OR COALESCE(therapy_gap_days,0) < 0
