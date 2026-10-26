SELECT *
FROM {{ source('veeva_align', 'zip_to_terr') }}
