SELECT *
FROM {{ source('iqvia_onekey', 'address_master') }}
