WITH source AS (
    SELECT * FROM {{ ref('raw_veeva_med_eve_attendees') }}
)


SELECT

    LOWER(NULLIF(TRIM(medical_event_attendee_id), ''))          AS event_attendee_id,
    NULLIF(TRIM(medical_event_id), '')                          AS medical_event_id,
    
    {{ normalize_npi('hcp_npi') }}                              AS hcp_npi,
    UPPER(NULLIF(TRIM(participant_role), ''))                   AS attendee_role,

    invitation_date                           AS invitation_date,
    UPPER(NULLIF(TRIM(invitation_status), ''))                  AS invitation_status,
    registration_date                         AS registration_date,
    UPPER(NULLIF(TRIM(registration_status), ''))                AS registration_status,
    UPPER(NULLIF(TRIM(attendance_status), ''))                  AS attendance_status,
    UPPER(NULLIF(TRIM(attendance_mode), ''))                    AS attendance_mode,

    TRY_TO_TIME(check_in_time::VARCHAR)                             AS check_in_time,
    TRY_TO_TIME(check_out_time::VARCHAR)                            AS check_out_time,
    
    {{ normalize_flag('no_show_flag') }}                        AS no_show_flag,
    cancellation_date                         AS cancellation_date,
    NULLIF(TRIM(eligibility_reason), '')                        AS eligibility_reason,
    
    TRY_TO_TIMESTAMP_NTZ(source_updated_at::VARCHAR)                AS source_updated_at,
    UPPER(NULLIF(TRIM(source_system), ''))                      AS source_system

FROM source
