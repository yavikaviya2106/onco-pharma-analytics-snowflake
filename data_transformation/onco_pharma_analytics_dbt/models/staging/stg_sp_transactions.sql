WITH source AS (
    SELECT * FROM {{ ref('raw_sp_transactions') }}
)


SELECT

    LOWER(NULLIF(TRIM(sp_transaction_id), ''))              AS sp_transaction_id,
    LOWER(NULLIF(TRIM(sp_case_id), ''))                     AS sp_case_id,
    LOWER(NULLIF(TRIM(hub_case_id), ''))                    AS hub_case_id,
    
    NULLIF(TRIM(patient_id::STRING), '')                    AS patient_id,
    TRY_TO_DECIMAL(patient_age::VARCHAR, 10,0)                    AS patient_age,
    UPPER(NULLIF(TRIM(gender), ''))                         AS gender,
    
    transaction_date                      AS transaction_date,
    UPPER(NULLIF(TRIM(transaction_type), ''))               AS transaction_type,
    UPPER(NULLIF(TRIM(transaction_status), ''))             AS transaction_status,
        
    NULLIF(TRIM(rx_number), '')                             AS rx_number,
    TRY_TO_DECIMAL(fill_number::VARCHAR, 10,0)                   AS fill_number,

    {{ normalize_ndc('ndc_code') }}                         AS ndc_code,

    TRY_TO_DECIMAL(quantity_prescribed::VARCHAR, 12,0)            AS quantity_prescribed,
    TRY_TO_DECIMAL(quantity_dispensed::VARCHAR, 12,0)             AS quantity_dispensed,
    
    NULLIF(TRIM(unit_of_measure), '')                       AS unit_of_measure,
    TRY_TO_DECIMAL(package_quantity::VARCHAR, 12,0)               AS package_quantity,
    TRY_TO_DECIMAL(package_count::VARCHAR, 12,0)                  AS package_count,
    TRY_TO_DECIMAL(units_per_day::VARCHAR, 10,2)                  AS units_per_day,
        
    TRY_TO_DECIMAL(days_supply::VARCHAR, 10,0)                   AS days_supply,
        
    shipment_date                         AS shipment_date,
    delivery_date                         AS delivery_date,
        
    NULLIF(TRIM(payer_id), '')                              AS payer_id,
    TRY_TO_DECIMAL(copay_amount::VARCHAR, 12,2)                  AS copay_amount,
        
    {{ normalize_npi('hcp_npi') }}                          AS hcp_npi,
        
    NULLIF(TRIM(sp_name), '')                               AS sp_name,
        
    sp_referral_date                      AS sp_referral_date,
    sp_enrollment_date                    AS sp_enrollment_date,
    insurance_verified_date               AS insurance_verified_date,
        
    {{ normalize_flag('pa_required_flag') }}                AS pa_required_flag,  
    pa_submission_date                    AS pa_submission_date,
    pa_decision_date                      AS pa_decision_date,
    UPPER(NULLIF(TRIM(pa_status), ''))                      AS pa_status,
        
    TRY_TO_DECIMAL(sp_case_avg_copay_amount::VARCHAR, 12,2)      AS sp_case_avg_copay_amount,
        
    {{ normalize_flag('financial_assistance_flag') }}       AS financial_assistance_flag,
    UPPER(NULLIF(TRIM(assistance_status), ''))              AS assistance_status,
        
    UPPER(NULLIF(TRIM(sp_case_status), ''))                 AS sp_case_status,
    UPPER(NULLIF(TRIM(sp_outcome), ''))                     AS sp_outcome,
    NULLIF(TRIM(sp_close_reason), '')                       AS sp_close_reason,
    sp_close_date                         AS sp_close_date,
        
    TRY_TO_TIMESTAMP_NTZ(source_updated_at::VARCHAR)            AS source_updated_at,
    UPPER(NULLIF(TRIM(source_system), ''))                  AS source_system

    FROM source
