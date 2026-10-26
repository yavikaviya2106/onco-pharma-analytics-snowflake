WITH source AS (
    SELECT * FROM {{ ref('raw_product_brand_details') }}
)


SELECT
        
    NULLIF(TRIM(brand_id), '')                          AS brand_id,
    NULLIF(TRIM(brand_name), '')                        AS brand_name,  
    NULLIF(TRIM(therapeutic_area), '')                  AS therapeutic_area,
        
    NULLIF(TRIM(company_id), '')                        AS company_id,
    NULLIF(TRIM(company_name), '')                      AS company_name,
        
    launch_date                       AS launch_date,
        
    TRY_TO_TIMESTAMP_NTZ(source_updated_at::VARCHAR)        AS source_updated_at,
    UPPER(NULLIF(TRIM(source_system), ''))              AS source_system

FROM source
