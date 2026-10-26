WITH source AS (
    SELECT * FROM {{ ref('raw_iqvia_onekey_hco_onekey') }}
)


SELECT

    NULLIF(TRIM(onekey_hco_id), '')                                 AS onekey_hco_id,
    {{ normalize_npi('npi') }}                                      AS hco_npi,
    
    NULLIF(TRIM(hin), '')                                           AS hin,
    NULLIF(TRIM(dea_number), '')                                    AS dea_number,
    NULLIF(TRIM(phs_id), '')                                        AS phs_id,
    NULLIF(TRIM(mpn), '')                                           AS mpn,
    NULLIF(TRIM(ims_id), '')                                        AS ims_id,
    NULLIF(TRIM(hce_id), '')                                        AS hce_id,
    
    NULLIF(TRIM(organization_legal_name), '')                       AS organization_legal_name,
    NULLIF(TRIM(doing_business_as_name), '')                        AS doing_business_as_name,
    NULLIF(TRIM(organization_short_name), '')                       AS organization_short_name,
    UPPER(NULLIF(TRIM(organization_status), ''))                    AS organization_status,
    NULLIF(TRIM(organization_type), '')                             AS organization_type,
    
    NULLIF(TRIM(class_of_trade), '')                                AS class_of_trade,
    NULLIF(TRIM(class_of_trade_level_1), '')                        AS class_of_trade_level_1,
    NULLIF(TRIM(class_of_trade_level_2), '')                        AS class_of_trade_level_2,
    NULLIF(TRIM(class_of_trade_level_3), '')                        AS class_of_trade_level_3,
    
    NULLIF(TRIM(facility_type), '')                                 AS facility_type,
    NULLIF(TRIM(specialty_type), '')                                AS specialty_type,

    {{ normalize_flag('hospital_flag') }}                           AS hospital_flag,
    {{ normalize_flag('medical_group_flag') }}                      AS medical_group_flag,
    {{ normalize_flag('clinic_flag') }}                             AS clinic_flag,
    {{ normalize_flag('nursing_home_flag') }}                       AS nursing_home_flag,
    {{ normalize_flag('pharmacy_flag') }}                           AS pharmacy_flag,
    {{ normalize_flag('gpo_flag') }}                                AS gpo_flag,
    {{ normalize_flag('idn_flag') }}                                AS idn_flag,
    {{ normalize_flag('aco_flag') }}                                AS aco_flag,
    {{ normalize_flag('ipa_flag') }}                                AS ipa_flag,

    NULLIF(TRIM(corporate_parent_onekey_hco_id), '')                AS corporate_parent_onekey_hco_id,
    NULLIF(TRIM(corporate_parent_name), '')                         AS corporate_parent_name,
    NULLIF(TRIM(idn_onekey_hco_id), '')                             AS idn_onekey_hco_id,
    NULLIF(TRIM(idn_name), '')                                      AS idn_name,
    NULLIF(TRIM(primary_address_id), '')                            AS primary_address_id,
    NULLIF(TRIM(secondary_address_id), '')                          AS secondary_address_id,
    NULLIF(TRIM(tertiary_address_id), '')                           AS tertiary_address_id,
    
    
    TRY_TO_DECIMAL(employee_count::VARCHAR, 12,0)                        AS employee_count,
    TRY_TO_DECIMAL(staffed_bed_count::VARCHAR, 12,0)                     AS staffed_bed_count,
    TRY_TO_DECIMAL(licensed_bed_count::VARCHAR, 12,0)                    AS licensed_bed_count,
    TRY_TO_DECIMAL(census_bed_count::VARCHAR, 12,0)                      AS census_bed_count,
    
    {{ normalize_flag('outpatient_flag') }}                         AS outpatient_flag,
    {{ normalize_flag('inpatient_flag') }}                          AS inpatient_flag,
    {{ normalize_flag('academic_medical_center_flag') }}            AS academic_medical_center_flag,
    {{ normalize_flag('teaching_hospital_flag') }}                  AS teaching_hospital_flag,
    
    UPPER(NULLIF(TRIM(record_status), ''))                          AS record_status,
    effective_start_date                                            AS effective_start_date,
    TRY_TO_DATE(effective_end_date::VARCHAR)                            AS effective_end_date,
        
    TRY_TO_TIMESTAMP_NTZ(source_updated_at::VARCHAR)                    AS source_updated_at,
    UPPER(NULLIF(TRIM(source_system), ''))                          AS source_system

    FROM source
