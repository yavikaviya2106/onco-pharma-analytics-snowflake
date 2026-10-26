SELECT *
FROM {{ source('product_mdm', 'sku_details') }}
