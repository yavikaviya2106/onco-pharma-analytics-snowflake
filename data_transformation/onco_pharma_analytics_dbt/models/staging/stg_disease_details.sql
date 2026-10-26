WITH source AS (
    SELECT * FROM {{ ref('raw_product_disease_details') }}
)


SELECT

    NULLIF(TRIM(disease_id), '')                    AS disease_id,
    NULLIF(TRIM(disease_name), '')                  AS disease_name,
        
    NULLIF(TRIM(therapeutic_area), '')              AS therapeutic_area,
    NULLIF(TRIM(cancer_area), '')                   AS cancer_type,
    {{ normalize_flag('biomarker_required') }}      AS biomarker_required,
    NULLIF(TRIM(biomarker_name), '')                AS biomarker_name,
    NULLIF(TRIM(diagnosis_specialties), '')         AS diagnosis_specialties,
    NULLIF(TRIM(prescribing_specialty), '')         AS prescribing_specialty,
    
    TRY_TO_TIMESTAMP_NTZ(source_updated_at::VARCHAR)    AS source_updated_at,
    UPPER(NULLIF(TRIM(source_system), ''))          AS source_system

FROM source
