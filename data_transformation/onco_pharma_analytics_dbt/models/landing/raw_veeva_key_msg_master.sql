SELECT *
FROM {{ source('veeva_crm', 'key_msg_master') }}
