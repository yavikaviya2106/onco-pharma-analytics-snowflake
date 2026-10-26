{{ config(tags=['p1','operational'], severity='error', enabled=var('p1_freshness_control_enabled', false)) }}

-- Requires an ingestion audit table with one row per successful delivery.
-- Does not infer row counts or cadence from filenames.

WITH schedule AS (
    SELECT 
        source_name, 
        table_name, 
        expected_by_ts 
    FROM {{ var('p1_delivery_schedule_relation') }}
    WHERE expected_by_ts <= CURRENT_TIMESTAMP()
), 

delivered AS (
    SELECT 
        source_name,
        table_name,
        delivery_date,
        MAX(completed_at) AS completed_at
    FROM {{ var('p1_ingestion_audit_relation') }} 
    WHERE status='SUCCESS'
    GROUP BY 1,2,3
)


SELECT 
    s.* 
FROM schedule s
WHERE 
    NOT EXISTS (
        SELECT 1 
        FROM delivered d
        WHERE d.source_name=s.source_name 
            AND d.table_name=s.table_name
            AND d.completed_at <= s.expected_by_ts 
            AND d.completed_at >= DATEADD(day,-1,s.expected_by_ts)
)
