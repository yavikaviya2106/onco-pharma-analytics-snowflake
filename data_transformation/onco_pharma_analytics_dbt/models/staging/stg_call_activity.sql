WITH source AS (
    SELECT * FROM {{ ref('raw_veeva_call_activity') }}
)


SELECT

    LOWER(NULLIF(TRIM(call_id), ''))                                AS call_id,
    call_date                                     AS call_date,
        
    NULLIF(TRIM(rep_id), '')                                        AS rep_id,
        
    LOWER(NULLIF(TRIM(hcp_id), ''))                                 AS hcp_id,
    {{ normalize_npi('hcp_npi') }}                                  AS hcp_npi,
    
    UPPER(NULLIF(TRIM(call_type), ''))                              AS call_type,
    UPPER(NULLIF(TRIM(call_status), ''))                            AS call_status,
    NULLIF(TRIM(call_outcome), '')                                  AS call_outcome,
        
    TRY_TO_DECIMAL(call_duration_minutes::VARCHAR, 10,0)                 AS call_duration_minutes,
    NULLIF(TRIM(call_purpose), '')                                  AS call_purpose,
    UPPER(NULLIF(TRIM(call_channel), ''))                           AS call_channel,
        
    {{ normalize_flag('is_planned_call') }}                         AS is_planned_call,
    {{ normalize_flag('is_target_hcp') }}                           AS is_target_hcp,
        
    TRY_TO_DECIMAL(call_sequence::VARCHAR, 10,0)                         AS call_sequence,
    {{ normalize_flag('key_message_presented') }}                   AS key_message_presented,
    {{ normalize_flag('sample_drop_flag') }}                        AS sample_drop_flag,
    
    {{ normalize_flag('follow_up_required') }}                      AS follow_up_required,
    follow_up_date                                AS follow_up_date,
    
    NULLIF(TRIM(location_type), '')                                 AS location_type,
    NULLIF(TRIM(location_name), '')                                 AS location_name,
   
    LOWER(NULLIF(TRIM(parent_call_id), ''))                         AS parent_call_id,
    NULLIF(TRIM(follow_up_action), '')                              AS follow_up_action,
    NULLIF(TRIM(next_best_action), '')                              AS next_best_action,
    
    TRY_TO_TIMESTAMP_NTZ(source_updated_at::VARCHAR)                    AS source_updated_at,
    UPPER(NULLIF(TRIM(source_system), ''))                          AS source_system

FROM source
