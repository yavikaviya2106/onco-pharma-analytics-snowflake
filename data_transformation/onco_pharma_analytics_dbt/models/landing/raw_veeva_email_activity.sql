SELECT *
FROM {{ source('veeva_crm', 'email_activity') }}
