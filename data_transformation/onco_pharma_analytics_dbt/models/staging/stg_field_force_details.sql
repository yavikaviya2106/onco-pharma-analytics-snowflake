WITH source AS (
    SELECT * FROM {{ ref('raw_internal_field_force_details') }}
)
   
   
SELECT

    NULLIF(TRIM(rep_id), '')                        AS rep_id,
    NULLIF(TRIM(rep_name), '')                      AS rep_name,
    
    NULLIF(TRIM(rep_role), '')                      AS rep_role,
    hire_date::DATE                                 AS hire_date,
    effective_start_date::DATE                      AS effective_start_date,
    effective_end_date::DATE                        AS effective_end_date,
    UPPER(NULLIF(TRIM(rep_status), ''))             AS rep_status,

    
    source_updated_at::TIMESTAMP_NTZ                AS source_updated_at,
    
    UPPER(NULLIF(TRIM(source_system), ''))          AS source_system

FROM source
