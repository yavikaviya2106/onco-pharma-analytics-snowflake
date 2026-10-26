WITH source AS (
    SELECT * FROM {{ ref('raw_veeva_email_activity') }}
)


SELECT

    LOWER(NULLIF(TRIM(email_activity_id), ''))               AS email_activity_id,
    
    LOWER(NULLIF(TRIM(hcp_id), ''))                          AS hcp_id,
    {{ normalize_npi('hcp_npi') }}                           AS hcp_npi,
        
    NULLIF(TRIM(rep_id), '')                                 AS rep_id,
    
    
    email_date                                               AS email_date, 
    NULLIF(TRIM(email_type), '')                             AS email_type,
    UPPER(NULLIF(TRIM(email_direction), ''))                 AS email_direction,
    NULLIF(TRIM(email_subject), '')                          AS email_subject,
    UPPER(NULLIF(TRIM(email_status), ''))                    AS email_status,
    UPPER(NULLIF(TRIM(email_response_status), ''))           AS email_response_status,
    response_date                          AS response_date,
    NULLIF(TRIM(email_priority), '')                         AS email_priority,
    
    {{ normalize_flag('opened_flag') }}                      AS opened_flag,
    open_date                              AS open_date,
    
    {{ normalize_flag('clicked_flag') }}                     AS clicked_flag, 
    click_date                             AS click_date,
    
    {{ normalize_flag('attachment_flag') }}                  AS attachment_flag,
    {{ normalize_flag('response_required_flag') }}           AS response_required_flag,                        
    
    NULLIF(TRIM(product_id), '')                             AS product_id,

    
    LOWER(NULLIF(TRIM(related_call_id), ''))                 AS related_call_id,
    LOWER(NULLIF(TRIM(related_event_id), ''))                AS related_event_id,
    NULLIF(TRIM(campaign_id), '')                            AS campaign_id,
    NULLIF(TRIM(email_channel), '')                          AS email_channel,
    
    TRY_TO_TIMESTAMP_NTZ(created_date::VARCHAR)                  AS created_date,
    
    TRY_TO_TIMESTAMP_NTZ(source_updated_at::VARCHAR)             AS source_updated_at,
    UPPER(NULLIF(TRIM(source_system), ''))                   AS source_system

FROM source
