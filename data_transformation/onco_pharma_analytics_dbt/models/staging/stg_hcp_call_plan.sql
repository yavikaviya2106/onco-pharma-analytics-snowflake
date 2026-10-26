WITH source AS (
    SELECT * FROM {{ ref('raw_internal_hcp_call_plan') }}
)


SELECT

    LOWER(NULLIF(TRIM(call_plan_id), ''))               AS call_plan_id,
        
    NULLIF(TRIM(cycle_id), '')                          AS cycle_id,
    NULLIF(TRIM(cycle_name), '')                        AS cycle_name,
        
    LOWER(NULLIF(TRIM(hcp_id), ''))                     AS hcp_id,
    {{ normalize_npi('hcp_npi') }}                      AS hcp_npi,
    NULLIF(TRIM(rep_id), '')                            AS rep_id,
   
    {{ normalize_flag('target_flag') }}                 AS target_flag,
    NULLIF(TRIM(target_priority), '')                   AS target_priority,
        
    TRY_TO_DECIMAL(min_call_frequency::VARCHAR, 10,0)        AS min_call_frequency,  
    TRY_TO_DECIMAL(planned_calls::VARCHAR, 10,0)             AS planned_calls, 
    TRY_TO_DECIMAL(max_call_frequency::VARCHAR, 10,0)        AS max_call_frequency,
        
    call_plan_start_date              AS call_plan_start_date,
    call_plan_end_date                AS call_plan_end_date,
        
    plan_created_date                 AS plan_created_date,
    NULLIF(TRIM(plan_approved_by), '')                  AS plan_approved_by,
        
    source_updated_at::TIMESTAMP_NTZ                    AS source_updated_at,
    UPPER(NULLIF(TRIM(source_system), ''))              AS source_system

FROM source
