WITH market AS (
    SELECT * FROM {{ ref('stg_market_details') }}
),

brand AS (
    SELECT 
        dim_brand_sk, 
        brand_id 
    FROM {{ ref('dim_brand_details') }}
),

generic AS (
    SELECT 
        dim_generic_sk, 
        generic_id 
    FROM {{ ref('dim_generic_details') }}
)

SELECT

    {{ dbt_utils.generate_surrogate_key(['market_id']) }} AS dim_market_sk,
    market.market_id                                      AS market_id,
    market.market_name                                    AS market_name,
    market.therapeutic_area                               AS therapeutic_area,
    
    generic.dim_generic_sk                                AS dim_generic_sk, 
    market.generic_id                                     AS generic_id,
    
    brand.dim_brand_sk                                    AS dim_brand_sk,
    market.brand_id                                       AS brand_id,

    market.source_updated_at                              AS source_updated_at

FROM market

LEFT JOIN brand 
    ON market.brand_id = brand.brand_id

LEFT JOIN generic 
    ON market.generic_id = generic.generic_id
