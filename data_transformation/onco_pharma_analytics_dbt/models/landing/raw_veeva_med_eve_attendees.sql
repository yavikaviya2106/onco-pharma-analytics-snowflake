SELECT *
FROM {{ source('veeva_crm', 'med_eve_attendees') }}
