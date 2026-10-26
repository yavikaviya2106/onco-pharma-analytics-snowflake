{{ config(severity='error', tags=['p1', 'temporal']) }}

-- Only calendar buckets must be non-overlapping within a type.
-- Rolling / to-date / LTD buckets overlap by design (see schema tests below).
WITH buckets AS (
    SELECT bucket_type, bucket_name, bucket_start_date, bucket_end_date
    FROM {{ ref('dim_time_bucket') }}
    WHERE bucket_type IN ('WEEK', 'MONTH', 'QUARTER', 'YEAR')
),

ordered AS (
    SELECT
        *,
        MAX(bucket_end_date) OVER (
            PARTITION BY bucket_type
            ORDER BY bucket_start_date, bucket_end_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        ) AS previous_max_end
    FROM buckets
)

SELECT *
FROM ordered
WHERE previous_max_end >= bucket_start_date