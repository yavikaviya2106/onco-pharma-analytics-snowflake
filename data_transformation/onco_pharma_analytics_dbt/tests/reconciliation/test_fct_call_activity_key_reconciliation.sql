{{ config(severity='error', tags=['quality_gate','p0']) }}

WITH source_keys AS (
    SELECT 
        call_id AS id, 
        COUNT(*) AS n 
    FROM {{ ref('stg_call_activity') }} 
    WHERE call_id IS NOT NULL GROUP BY 1
),

target_keys AS (
    SELECT 
        call_id AS id, 
        COUNT(*) AS n 
    FROM {{ ref('fct_call_activity') }} 
    WHERE call_id IS NOT NULL GROUP BY 1
)

SELECT 
    COALESCE(s.id,t.id) AS id,
    COALESCE(s.n,0) AS source_rows, 
    COALESCE(t.n,0) AS target_rows
FROM source_keys s
FULL OUTER JOIN target_keys t 
    ON s.id=t.id
WHERE COALESCE(s.n,0) <> COALESCE(t.n,0)
