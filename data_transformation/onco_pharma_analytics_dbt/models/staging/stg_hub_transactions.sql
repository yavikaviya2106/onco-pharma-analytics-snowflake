WITH source AS (
    SELECT * FROM {{ ref('raw_hub_transactions') }}
)
    

SELECT

    LOWER(NULLIF(TRIM(hub_case_id), ''))                                AS hub_case_id,
        
    NULLIF(TRIM(patient_id::STRING), '')                                AS patient_id,
    TRY_TO_DECIMAL(patient_age::VARCHAR, 10,0)                               AS patient_age,
    UPPER(NULLIF(TRIM(gender), ''))                                     AS gender,
        
    {{ normalize_npi('hcp_npi') }}                                      AS hcp_npi,
        
    {{ normalize_ndc('ndc_code') }}                                     AS ndc_code,
    
    referral_date                                     AS referral_date,
    hub_enrollment_date                               AS hub_enrollment_date,
    UPPER(NULLIF(TRIM(hub_case_status), ''))                            AS hub_case_status,
        
    UPPER(NULLIF(TRIM(benefit_verification_status), ''))                AS benefit_verification_status,
    NULLIF(TRIM(insurance_type), '')                                    AS insurance_type,
    NULLIF(TRIM(payer_id), '')                                          AS payer_id,
    
    {{ normalize_flag('pa_required_flag') }}                                AS pa_required_flag,
    pa_submission_date                                AS pa_submission_date,
    pa_decision_date                                  AS pa_decision_date,
    UPPER(NULLIF(TRIM(pa_status), ''))                                  AS pa_status,
        
    {{ normalize_flag('appeal_flag') }}                                     AS appeal_flag,
    appeal_submission_date                            AS appeal_submission_date,
    NULLIF(TRIM(appeal_decision), '')                                   AS appeal_decision,
  
    
    {{ normalize_flag('pap_eligible_flag') }}                               AS pap_eligible_flag,
    pap_enrollment_date                               AS pap_enrollment_date,
    pap_approval_date                                 AS pap_approval_date,
        
    {{ normalize_flag('financial_assistance_flag') }}                       AS financial_assistance_flag,
    {{ normalize_flag('copay_assistance_flag') }}                           AS copay_assistance_flag,
    
    {{ normalize_flag('sp_referral_flag') }}                                AS sp_referral_flag,
    sp_referral_date                                  AS sp_referral_date,
       
    
    NULLIF(TRIM(hub_close_reason), '')                                  AS hub_close_reason,
    hub_close_date                                    AS hub_close_date,
    
    LOWER(NULLIF(TRIM(hub_pap_transaction_id), ''))                     AS hub_pap_transaction_id,
    transaction_date                                  AS transaction_date,
    UPPER(NULLIF(TRIM(transaction_type), ''))                           AS transaction_type,
    UPPER(NULLIF(TRIM(transaction_status), ''))                         AS transaction_status,
    NULLIF(TRIM(pap_program_id), '')                                    AS pap_program_id,
    
    TRY_TO_DECIMAL(quantity_requested::VARCHAR, 12,0)                        AS quantity_requested,
    TRY_TO_DECIMAL(quantity_approved::VARCHAR, 12,0)                         AS quantity_approved,
    TRY_TO_DECIMAL(quantity_dispensed::VARCHAR, 12,0)                        AS quantity_dispensed,
    TRY_TO_DECIMAL(fill_number::VARCHAR, 10,0)                               AS fill_number,

    NULLIF(TRIM(unit_of_measure), '')                                   AS unit_of_measure,
    TRY_TO_DECIMAL(package_quantity::VARCHAR, 12,0)                          AS package_quantity,
    TRY_TO_DECIMAL(package_count::VARCHAR, 12,0)                             AS package_count,
    TRY_TO_DECIMAL(days_supply::VARCHAR, 10,0)                               AS days_supply,
    TRY_TO_DECIMAL(units_per_day::VARCHAR, 10,2)                             AS units_per_day,
    
    shipment_date                                     AS shipment_date,
    delivery_date                                     AS delivery_date,
        
    NULLIF(TRIM(pap_reason), '')                                        AS pap_reason,
    UPPER(NULLIF(TRIM(pap_outcome), ''))                                AS pap_outcome,
    
    TRY_TO_TIMESTAMP_NTZ(source_updated_at::VARCHAR)                        AS source_updated_at,
    UPPER(NULLIF(TRIM(source_system), ''))                              AS source_system

FROM source
