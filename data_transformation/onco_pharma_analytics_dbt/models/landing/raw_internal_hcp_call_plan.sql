SELECT *
FROM {{ source('internal_mdm', 'hcp_call_plan') }}
