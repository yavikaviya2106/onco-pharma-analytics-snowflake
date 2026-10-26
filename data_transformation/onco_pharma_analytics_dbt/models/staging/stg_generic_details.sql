WITH source AS (
    SELECT * FROM {{ ref('raw_product_generic_details') }}
)


SELECT

    NULLIF(TRIM(generic_id), '')                    AS generic_id,
    NULLIF(TRIM(generic_name), '')                  AS generic_name,
    
    NULLIF(TRIM(therapeutic_area), '')              AS therapeutic_area,
        
    NULLIF(TRIM(drug_class), '')                    AS drug_class,
    NULLIF(TRIM(mechanism_action), '')              AS mechanism_action,
    NULLIF(TRIM(targets), '')                       AS targets,
        
    TRY_TO_TIMESTAMP_NTZ(source_updated_at::VARCHAR)    AS source_updated_at,
    UPPER(NULLIF(TRIM(source_system), ''))          AS source_system,

FROM source
