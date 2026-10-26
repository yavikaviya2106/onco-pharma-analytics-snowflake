SELECT *
FROM {{ source('iqvia', 'iqvia_ddd') }}
