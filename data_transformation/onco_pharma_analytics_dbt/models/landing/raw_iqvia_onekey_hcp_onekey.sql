SELECT *
FROM {{ source('iqvia_onekey', 'hcp_onekey') }}
