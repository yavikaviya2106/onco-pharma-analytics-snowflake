WITH source AS (
    SELECT * FROM {{ ref('raw_veeva_call_detail') }}
)
    

SELECT

    LOWER(NULLIF(TRIM(call_detail_id), ''))              AS call_detail_id,
    LOWER(NULLIF(TRIM(call_id), ''))                     AS call_id,
    
    NULLIF(TRIM(product_id), '')                         AS product_id,
    TRY_TO_DECIMAL(product_position::VARCHAR, 10,0)            AS product_position,
        
    NULLIF(TRIM(key_message_id), '')                     AS key_message_id,
    NULLIF(TRIM(message_theme), '')                      AS message_theme,
        
    UPPER(NULLIF(TRIM(detail_type), ''))                 AS detail_type,
    UPPER(NULLIF(TRIM(detail_priority), ''))             AS detail_priority,
    {{ normalize_flag('discussion_flag') }}              AS discussion_flag,
    NULLIF(TRIM(presentation_type), '')                  AS presentation_type,
    
    NULLIF(TRIM(hcp_reaction), '')                       AS hcp_reaction,
    NULLIF(TRIM(hcp_response), '')                       AS hcp_response,
    NULLIF(TRIM(hcp_interest_level), '')                 AS hcp_interest_level,

    {{ normalize_flag('objection_flag') }}               AS objection_flag,
    NULLIF(TRIM(objection_type), '')                     AS objection_type,
    NULLIF(TRIM(detail_notes), '')                       AS detail_notes,
        
    TRY_TO_TIMESTAMP_NTZ(source_updated_at::VARCHAR)         AS source_updated_at,
    UPPER(NULLIF(TRIM(source_system), ''))               AS source_system

FROM source
