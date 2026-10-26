SELECT *
FROM {{ source('iqvia_onekey', 'hco_onekey') }}
