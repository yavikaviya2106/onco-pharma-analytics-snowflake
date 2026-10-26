WITH source AS (
    SELECT * FROM {{ ref('raw_iqvia_onekey_hcp_hco_affiliation') }}
)


SELECT

    NULLIF(TRIM(affiliation_id), '')                                   AS affiliation_id,

    NULLIF(TRIM(hcp_id), '')                                           AS onekey_hcp_id,
    NULLIF(TRIM(onekey_hco_id), '')                                    AS onekey_hco_id,
    NULLIF(TRIM(address_id), '')                                       AS address_id,

    {{ normalize_flag('primary_affiliation_flag') }}                   AS primary_affiliation_flag,
    {{ normalize_flag('best_affiliation_flag') }}                      AS best_affiliation_flag,
    effective_start_date                             AS effective_start_date,
    effective_end_date                               AS effective_end_date,
    NULLIF(TRIM(status), '')                                           AS status,

    NULLIF(TRIM(relationship_type), '')                                AS relationship_type,
    NULLIF(TRIM(affiliation_type), '')                                 AS affiliation_type,
    NULLIF(TRIM(affiliation_sub_type), '')                             AS affiliation_sub_type,
    NULLIF(TRIM(affiliation_role), '')                                 AS affiliation_role,
     NULLIF(TRIM(affiliation_rank), '')                                AS affiliation_rank,
    {{ normalize_flag('employment_flag') }}                            AS employment_flag,
    UPPER(NULLIF(TRIM(employment_status), ''))                         AS employment_status,
    NULLIF(TRIM(department_at_hco), '')                                AS department_at_hco,
    NULLIF(TRIM(specialty_at_hco), '')                                 AS specialty_at_hco,
    
    {{ normalize_flag('practice_location_flag') }}                     AS practice_location_flag,
    {{ normalize_flag('hospital_affiliation_flag') }}                  AS hospital_affiliation_flag,
    {{ normalize_flag('medical_group_affiliation_flag') }}             AS medical_group_affiliation_flag,
    {{ normalize_flag('idn_affiliation_flag') }}                       AS idn_affiliation_flag,
    {{ normalize_flag('gpo_affiliation_flag') }}                       AS gpo_affiliation_flag,
    {{ normalize_flag('corporate_parent_affiliation_flag') }}          AS corporate_parent_affiliation_flag,
    {{ normalize_flag('out_of_state_flag') }}                          AS out_of_state_flag,

    verification_date                                AS verification_date,
    UPPER(NULLIF(TRIM(confidence_level), ''))                          AS confidence_level,
    NULLIF(TRIM(source_type), '')                                      AS source_type,
       
    TRY_TO_TIMESTAMP_NTZ(source_updated_at::VARCHAR)                       AS source_updated_at,
    UPPER(NULLIF(TRIM(source_system), ''))                             AS source_system

    FROM source
