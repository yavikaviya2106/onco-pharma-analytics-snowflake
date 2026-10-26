SELECT *
FROM {{ source('product_mdm', 'brand_details') }}
