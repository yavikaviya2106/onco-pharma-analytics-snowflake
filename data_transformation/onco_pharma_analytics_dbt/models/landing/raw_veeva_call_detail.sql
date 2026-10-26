SELECT *
FROM {{ source('veeva_crm', 'call_detail') }}
