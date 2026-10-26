WITH source AS (
    SELECT * FROM {{ ref('raw_veeva_med_eve_master') }}
)


SELECT

    NULLIF(TRIM(medical_event_id), '')                          AS medical_event_id,
    
    NULLIF(TRIM(event_name), '')                                AS event_name,
    NULLIF(TRIM(event_type), '')                                AS event_type,
    NULLIF(TRIM(event_category), '')                            AS event_category,
    UPPER(NULLIF(TRIM(event_status), ''))                       AS event_status,
    NULLIF(TRIM(event_description), '')                         AS event_description,
    UPPER(NULLIF(TRIM(event_format), ''))                       AS event_format,
        
    event_start_date                          AS event_start_date,
    event_end_date                            AS event_end_date,
    TRY_TO_TIME(event_start_time::VARCHAR)                          AS event_start_time,
    TRY_TO_TIME(event_end_time::VARCHAR)                            AS event_end_time,
    NULLIF(TRIM(timezone), '')                                  AS timezone,
        
    NULLIF(TRIM(venue_name), '')                                AS venue_name,
    NULLIF(TRIM(venue_address), '')                             AS venue_address,
    NULLIF(TRIM(city), '')                                      AS city,
    UPPER(NULLIF(TRIM(state), ''))                              AS state,
    UPPER(NULLIF(TRIM(country), ''))                            AS country,
        
    NULLIF(TRIM(virtual_platform), '')                          AS virtual_platform,
    NULLIF(TRIM(virtual_event_url), '')                         AS virtual_event_url,
       
    NULLIF(TRIM(therapeutic_area), '')                          AS therapeutic_area,
    NULLIF(TRIM(disease_id), '')                                AS disease_id,
    NULLIF(TRIM(primary_product_id), '')                        AS primary_product_id,
    NULLIF(TRIM(indication_id), '')                             AS indication_id,
        
    NULLIF(TRIM(sponsor_name), '')                              AS sponsor_name,
    NULLIF(TRIM(organizing_department), '')                     AS organizing_department,
    NULLIF(TRIM(event_owner_id), '')                            AS event_owner_id,
    NULLIF(TRIM(event_coordinator), '')                         AS event_coordinator,
    NULLIF(TRIM(agency_name), '')                               AS agency_name,
        
    {{ normalize_npi('primary_speaker_npi') }}                  AS primary_speaker_npi,
        
    TRY_TO_DECIMAL(planned_attendee_count::VARCHAR, 12,0)            AS planned_attendee_count,
    TRY_TO_DECIMAL(actual_attendee_count::VARCHAR, 12,0)             AS actual_attendee_count,
    TRY_TO_DECIMAL(target_attendee_count::VARCHAR, 12,0)             AS target_attendee_count,
    TRY_TO_DECIMAL(registration_count::VARCHAR, 12,0)                AS registration_count,
    TRY_TO_DECIMAL(event_capacity::VARCHAR, 10,0)                    AS event_capacity,
    
    {{ normalize_flag('compliance_required_flag') }}                AS compliance_required_flag,
    UPPER(NULLIF(TRIM(compliance_status), ''))                  AS compliance_status,
    UPPER(NULLIF(TRIM(approval_status), ''))                    AS approval_status,
    approval_date                             AS approval_date,
    NULLIF(TRIM(approval_reference_id), '')                     AS approval_reference_id,
    
    TRY_TO_DECIMAL(event_budget::VARCHAR, 10,0)                      AS event_budget,
    TRY_TO_DECIMAL(actual_event_cost::VARCHAR, 10,0)                 AS actual_event_cost,
    UPPER(NULLIF(TRIM(currency_code), ''))                      AS currency_code,
    
    TRY_TO_TIMESTAMP_NTZ(source_updated_at::VARCHAR)                AS source_updated_at,
    UPPER(NULLIF(TRIM(source_system), ''))                      AS source_system

    FROM source
