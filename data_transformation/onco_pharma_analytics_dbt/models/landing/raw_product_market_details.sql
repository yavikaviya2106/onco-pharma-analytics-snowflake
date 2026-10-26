SELECT *
FROM {{ source('product_mdm', 'market_details') }}
