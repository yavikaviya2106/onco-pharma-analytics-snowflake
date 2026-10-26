SELECT *
FROM {{ source('product_mdm', 'product_details') }}
