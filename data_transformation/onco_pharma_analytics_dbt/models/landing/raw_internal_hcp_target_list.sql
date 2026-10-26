SELECT *
FROM {{ source('internal_mdm', 'hcp_target_list') }}
