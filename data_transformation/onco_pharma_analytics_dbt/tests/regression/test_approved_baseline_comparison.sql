{{ config(tags=['p1','deployment'], severity='error', enabled=var('p1_baseline_enabled', false)) }}


-- Approved baseline is a persisted table created BEFORE the candidate run.
-- Grain: model_name, metric_name, grain_key, metric_value; compare only approved stable periods.

WITH candidate AS (
    SELECT 
        model_name,
        metric_name,
        grain_key,
        metric_value 
    FROM {{ var('p1_candidate_metrics_relation') }}
), 

baseline AS (
    SELECT 
        model_name,
        metric_name,
        grain_key,
        metric_value 
    FROM {{ var('p1_approved_baseline_relation') }}
)


SELECT 
    COALESCE(c.model_name,b.model_name) model_name,
    COALESCE(c.metric_name,b.metric_name) metric_name,
    COALESCE(c.grain_key,b.grain_key) grain_key,
    b.metric_value baseline_value,
    c.metric_value candidate_value
FROM candidate c 
FULL OUTER JOIN baseline b
    ON c.model_name=b.model_name 
        AND c.metric_name=b.metric_name 
        AND c.grain_key=b.grain_key

WHERE c.metric_value IS NULL 
    OR b.metric_value IS NULL
    OR ABS(c.metric_value-b.metric_value) > {{ var('p1_baseline_tolerance',0) }}
