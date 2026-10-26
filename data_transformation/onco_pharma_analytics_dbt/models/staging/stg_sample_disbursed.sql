WITH source AS (
    SELECT * FROM {{ ref('raw_veeva_samples_disbursed') }}

)

SELECT

    LOWER(NULLIF(TRIM(call_id), ''))                        AS call_id,
    LOWER(NULLIF(TRIM(call_detail_id), ''))                 AS call_detail_id,
        
    NULLIF(TRIM(rep_id), '')                                AS rep_id,
        
    NULLIF(TRIM(product_id), '')                            AS product_id,
    
    NULLIF(TRIM(sample_id), '')                             AS sample_id,
    NULLIF(TRIM(sample_lot_number), '')                     AS sample_lot_number,
    TRY_TO_DECIMAL(sample_quantity::VARCHAR, 12,0)          AS sample_quantity,
    NULLIF(TRIM(sample_unit), '')                           AS sample_unit,
    UPPER(NULLIF(TRIM(sample_type), ''))                    AS sample_type,
    UPPER(NULLIF(TRIM(sample_status), ''))                  AS sample_status,
        
    disbursement_date                     AS disbursement_date,
    expiration_date                       AS expiration_date,
                           
    {{ normalize_flag('signature_captured_flag') }}         AS signature_captured_flag,
    {{ normalize_flag('acknowledgement_flag') }}            AS acknowledgement_flag,
    {{ normalize_flag('return_required_flag') }}            AS return_required_flag,
    
    return_date                           AS return_date,
    TRY_TO_DECIMAL(return_quantity::VARCHAR, 12,0)               AS return_quantity,
    NULLIF(TRIM(return_reason), '')                         AS return_reason,
    NULLIF(TRIM(disbursement_reason), '')                   AS disbursement_reason,
    UPPER(NULLIF(TRIM(sample_recipient_type), ''))          AS sample_recipient_type,
    NULLIF(TRIM(notes), '') AS notes,
    
    TRY_TO_TIMESTAMP_NTZ(source_updated_at::VARCHAR)             AS source_updated_at,
    UPPER(NULLIF(TRIM(source_system), ''))                   AS source_system

FROM source
