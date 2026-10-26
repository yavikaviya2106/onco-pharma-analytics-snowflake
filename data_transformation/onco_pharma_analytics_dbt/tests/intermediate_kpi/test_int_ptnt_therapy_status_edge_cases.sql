{{ config(tags=['p1','kpi_edge'], severity='error') }}

SELECT 
    patient_id, 
    product_id, 
    therapy_status
FROM {{ ref('int_ptnt_therapy') }}
WHERE (COALESCE(active_patient_flag,FALSE) AND (COALESCE(inactive_patient_flag,FALSE) OR COALESCE(current_explicit_discontinued_flag,FALSE)))
 OR (COALESCE(restarted_patient_flag,FALSE) AND (first_restart_date IS NULL OR therapy_episode_count < 2))
 OR (COALESCE(therapy_started_flag,FALSE) AND therapy_start_date IS NULL)
 OR (NOT COALESCE(therapy_started_flag,FALSE) AND therapy_status <> 'NOT_STARTED')
 OR (COALESCE(persistent_365_flag,FALSE) AND NOT COALESCE(persistent_180_flag,FALSE))
 OR (COALESCE(persistent_180_flag,FALSE) AND NOT COALESCE(persistent_90_flag,FALSE))
 OR (COALESCE(persistent_90_flag,FALSE) AND NOT COALESCE(persistent_30_flag,FALSE))
 OR (COALESCE(discontinued_patient_flag,FALSE) AND latest_discontinuation_date IS NULL)
