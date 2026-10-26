WITH source AS (
    SELECT * FROM {{ ref('raw_veeva_key_msg_master') }}
)


SELECT

    NULLIF(TRIM(key_message_id), '')                    AS key_message_id,
    
    NULLIF(TRIM(product_id), '')                        AS product_id,
    
    NULLIF(TRIM(message_title), '')                     AS message_title,
    NULLIF(TRIM(message_text), '')                      AS message_text,
    NULLIF(TRIM(message_type), '')                      AS message_type,
    
    NULLIF(TRIM(therapeutic_area), '')                  AS therapeutic_area,
    NULLIF(TRIM(indication), '')                        AS indication,
    NULLIF(TRIM(target_specialty), '')                  AS target_specialty,
    UPPER(NULLIF(TRIM(priority), ''))                   AS priority,
    TRY_TO_DECIMAL(sequence::VARCHAR, 10,0)                  AS sequence,
    
    effective_start_date              AS effective_start_date,
    effective_end_date                AS effective_end_date,
    UPPER(NULLIF(TRIM(approval_status), ''))            AS approval_status,
    approved_date                     AS approved_date,
    
    NULLIF(TRIM(content_version), '')                   AS content_version,
    NULLIF(TRIM(objection_handling), '')                AS objection_handling,
    
    NULLIF(TRIM(source_reference), '')                  AS source_reference,
    
    TRY_TO_TIMESTAMP_NTZ(source_updated_at::VARCHAR)        AS source_updated_at,
    UPPER(NULLIF(TRIM(source_system), ''))              AS source_system

FROM source
