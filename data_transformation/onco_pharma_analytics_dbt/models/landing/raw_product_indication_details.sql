SELECT *
FROM {{ source('product_mdm', 'drug_indication_details') }}
