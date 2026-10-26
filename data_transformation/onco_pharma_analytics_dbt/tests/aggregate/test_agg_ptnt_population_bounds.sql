{{ config(severity='error', tags=['quality_gate','p0']) }}

SELECT * FROM {{ ref('agg_ptnt_period_performance') }} 
WHERE observed_patient_population < 0 
    OR new_observed_patients > observed_patient_population 
    OR sp_dispensed_patients > dispensed_patients 
    OR pap_dispensed_patients > dispensed_patients 
    OR new_dispensed_patients > cumulative_dispensed_patients 
    OR new_therapy_patients > cumulative_therapy_patients

