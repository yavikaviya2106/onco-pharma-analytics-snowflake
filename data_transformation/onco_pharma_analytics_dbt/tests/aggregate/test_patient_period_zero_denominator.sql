{{ config(severity='error', tags=['p1','kpi_edge']) }}

-- Core zero-population / zero-fill invariants, independent of optional rate column names.

SELECT
    dim_prod_sk,
    bucket_type,
    bucket_name
FROM {{ ref('agg_ptnt_period_performance') }}
WHERE (observed_patient_population = 0 AND total_fills > 0)
   OR (total_fills = 0 AND total_refills > 0)
   OR (total_refills > total_fills)
   OR (sp_fills + pap_fills <> total_fills)