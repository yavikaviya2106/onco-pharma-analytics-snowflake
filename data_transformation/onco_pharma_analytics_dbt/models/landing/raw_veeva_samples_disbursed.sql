SELECT *
FROM {{ source('veeva_crm', 'samples_disbursed') }}
