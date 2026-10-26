{{ config(severity='error', tags=['p1','temporal']) }}

WITH buckets AS (
 SELECT 'GLOBAL' AS scope, bucket_type, bucket_name,bucket_start_date,bucket_end_date FROM {{ ref('dim_time_bucket') }}
 UNION ALL
 SELECT product_id AS scope,bucket_type,bucket_name,bucket_start_date,bucket_end_date FROM {{ ref('dim_pdt_time_bucket') }}
)

SELECT * FROM buckets 
WHERE bucket_start_date IS NULL 
    OR bucket_end_date IS NULL 
    OR bucket_end_date < bucket_start_date
