SELECT *
FROM {{ source('product_mdm', 'generic_details') }}
