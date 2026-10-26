SELECT *
FROM {{ source('iqvia_onekey', 'hcp_hco_affiliation') }}
