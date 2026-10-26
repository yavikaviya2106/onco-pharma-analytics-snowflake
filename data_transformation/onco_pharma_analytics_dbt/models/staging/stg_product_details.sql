WITH source AS (
    SELECT * FROM {{ ref('raw_product_product_details') }}
)

    
SELECT

    NULLIF(TRIM(product_id), '')                        AS product_id,
    NULLIF(TRIM(product_name), '')                      AS product_name,
        
    NULLIF(TRIM(brand_id), '')                          AS brand_id,
    NULLIF(TRIM(generic_id), '')                        AS generic_id,
        
    {{ normalize_ndc('ndc_code') }}                     AS ndc_code,
    TRY_TO_DECIMAL(strength::VARCHAR, 10,2)                   AS strength,
    NULLIF(TRIM(strength_unit), '')                     AS strength_unit,
    UPPER(NULLIF(TRIM(dosage_form), ''))                AS dosage_form,
    UPPER(NULLIF(TRIM(route_of_administration), ''))    AS route_of_administration,
    NULLIF(TRIM(pack_type), '')                         AS pack_type,
    TRY_TO_DECIMAL(pack_size::VARCHAR, 10,0)                  AS pack_size,
    
    CAST(launch_date AS DATE)                           AS launch_date,
    UPPER(NULLIF(TRIM(status), ''))                     AS status,
    
    CAST(source_updated_at AS TIMESTAMP_NTZ)            AS source_updated_at,
    UPPER(NULLIF(TRIM(source_system), ''))              AS source_system

FROM source
