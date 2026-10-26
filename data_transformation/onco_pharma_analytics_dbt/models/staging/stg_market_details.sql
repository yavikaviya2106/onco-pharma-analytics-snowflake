WITH source AS (
    SELECT * FROM {{ ref('raw_product_market_details') }}
)


SELECT
        
    NULLIF(TRIM(market_id), '')                     AS market_id,
    NULLIF(TRIM(market_name), '')                   AS market_name,
   
    NULLIF(TRIM(therapeutic_area), '')              AS therapeutic_area,
    
    NULLIF(TRIM(generic_id), '')                    AS generic_id,
    NULLIF(TRIM(brand_id), '')                      AS brand_id,
    
    TRY_TO_TIMESTAMP_NTZ(source_updated_at::VARCHAR)    AS source_updated_at,
    UPPER(NULLIF(TRIM(source_system), ''))          AS source_system

FROM source
