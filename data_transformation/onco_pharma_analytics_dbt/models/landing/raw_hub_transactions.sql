SELECT *
FROM {{ source('hub', 'hub_transactions') }}
