SELECT *
FROM {{ source('internal_mdm', 'field_force_details') }}
