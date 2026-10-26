SELECT *
FROM {{ source('sp', 'sp_transactions') }}
