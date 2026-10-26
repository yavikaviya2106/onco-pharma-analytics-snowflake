WITH source AS (
    SELECT * FROM {{ ref('raw_internal_hcp_target_list') }}
)


SELECT

    NULLIF(TRIM(target_list_id), '')                        AS target_list_id,
    NULLIF(TRIM(target_list_name), '')                      AS target_list_name,
        
    LOWER(NULLIF(TRIM(hcp_id), ''))                         AS hcp_id,
    {{ normalize_npi('hcp_npi') }}                          AS hcp_npi,
        
    {{ normalize_flag('target_flag') }}                     AS target_flag,
    TRY_TO_DECIMAL(target_priority::VARCHAR, 10,0)                AS target_priority,
    UPPER(NULLIF(TRIM(target_segment), ''))                 AS target_segment,   
    TRY_TO_DECIMAL(target_rank::VARCHAR, 10,0)                   AS target_rank,
    NULLIF(TRIM(target_reason), '')                         AS target_reason,
    TRY_TO_DECIMAL(target_score::VARCHAR, 5,2)                  AS target_score,
        
    UPPER(NULLIF(TRIM(target_status), ''))                  AS target_status,
    effective_from                        AS effective_from,
    effective_to                          AS effective_to,
    
    source_updated_at::TIMESTAMP_NTZ                        AS source_updated_at,
    UPPER(NULLIF(TRIM(source_system), ''))                  AS source_system

FROM source
