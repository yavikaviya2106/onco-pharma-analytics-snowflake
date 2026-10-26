WITH source AS (
    SELECT * FROM {{ ref('raw_iqvia_onekey_hcp_onekey') }}
)
  
    
SELECT

    NULLIF(TRIM(onekey_hcp_id), '')                                         AS onekey_hcp_id,
    {{ normalize_npi('npi') }}                                              AS npi,
    
    NULLIF(TRIM(ama_id), '')                                                AS ama_id,
    NULLIF(TRIM(dea_number), '')                                            AS dea_number,
    
    NULLIF(TRIM(state_license_number), '')                                  AS state_license_number,
    UPPER(NULLIF(TRIM(state_license_state), ''))                            AS state_license_state,
    NULLIF(TRIM(license_type), '')                                          AS license_type,
    NULLIF(TRIM(license_privilege), '')                                     AS license_privilege,
        
    NULLIF(TRIM(full_name), '')                                             AS full_name,
    UPPER(NULLIF(TRIM(gender), ''))                                         AS gender,
        
    UPPER(NULLIF(TRIM(professional_status), ''))                            AS professional_status,
    NULLIF(TRIM(profession_type), '')                                       AS profession_type,
    NULLIF(TRIM(credentials), '')                                           AS credentials,
        
    NULLIF(TRIM(primary_specialty), '')                                     AS primary_specialty,
    UPPER(NULLIF(TRIM(primary_specialty_code), ''))                         AS primary_specialty_code,
    NULLIF(TRIM(secondary_specialty), '')                                   AS secondary_specialty,
    UPPER(NULLIF(TRIM(secondary_specialty_code), ''))                       AS secondary_specialty_code,
    NULLIF(TRIM(sub_specialty), '')                                         AS sub_specialty,
    UPPER(NULLIF(TRIM(sub_specialty_code), ''))                             AS sub_specialty_code,
    
    {{ normalize_flag('board_certified_flag') }}                            AS board_certified_flag,
    NULLIF(TRIM(board_certification), '')                                   AS board_certification,
    
    {{ normalize_flag('prescriber_flag') }}                                 AS prescriber_flag,
    UPPER(NULLIF(TRIM(prescribing_status), ''))                             AS prescribing_status,
    
    {{ normalize_flag('pdrp_optout_flag') }}                                AS pdrp_flag,
    {{ normalize_flag('patient_facing_flag') }}                             AS patient_facing_flag,
    {{ normalize_flag('hospital_based_flag') }}                             AS hospital_based_flag,
    {{ normalize_flag('academic_flag') }}                                   AS academic_flag,
    {{ normalize_flag('key_decision_maker_flag') }}                         AS key_decision_maker_flag,
    {{ normalize_flag('key_opinion_leader_flag') }}                         AS key_opinion_leader_flag,
    {{ normalize_flag('sample_eligibility_flag') }}                         AS sample_eligibility_flag,    
    {{ normalize_flag('controlled_sample_eligibility') }}                   AS controlled_sample_eligibility,
    {{ normalize_flag('noncontrolled_sample_eligibility') }}                AS noncontrolled_sample_eligibility,
    
    NULLIF(TRIM(primary_employer_hco_id), '')                               AS primary_employer_hco_id,
    NULLIF(TRIM(practice_setting), '')                                      AS practice_setting,

    NULLIF(TRIM(primary_affiliation_id), '')                                AS primary_affiliation_id,
    NULLIF(TRIM(affiliation_count), '')                                     AS affiliation_count,

    LOWER(NULLIF(TRIM(digital_id), ''))                                     AS digital_id,
    {{ normalize_flag('digital_presence_flag') }}                           AS digital_presence_flag,
    
    NULLIF(TRIM(communication_preference), '')                              AS communication_preference,
    NULLIF(TRIM(channel_preference), '')                                    AS channel_preference,
    NULLIF(TRIM(language_preference), '')                                   AS language_preference,
    
    TRY_TO_TIMESTAMP_NTZ(source_updated_at::VARCHAR)                        AS source_updated_at,
    UPPER(NULLIF(TRIM(source_system), ''))                                  AS source_system

FROM source
