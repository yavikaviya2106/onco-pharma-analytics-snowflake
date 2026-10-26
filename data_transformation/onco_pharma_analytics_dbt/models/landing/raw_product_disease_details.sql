SELECT *
FROM {{ source('product_mdm', 'disease_details') }}
