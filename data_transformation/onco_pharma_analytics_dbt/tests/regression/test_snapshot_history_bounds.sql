{{ config(tags=['p1','snapshot'], severity='error') }}
{% set snapshot_model = var('p1_snapshot_model', 'field_force_snapshot') %}
{% set natural_key = var('p1_snapshot_natural_key', 'rep_id') %}
WITH history AS (
 SELECT {{ natural_key }} AS natural_id,dbt_valid_from,dbt_valid_to,
 LEAD(dbt_valid_from) OVER(PARTITION BY {{ natural_key }} ORDER BY dbt_valid_from) AS next_start
 FROM {{ ref(snapshot_model) }}
)
SELECT * FROM history
WHERE dbt_valid_from IS NULL OR (dbt_valid_to IS NOT NULL AND dbt_valid_to <= dbt_valid_from)
 OR (next_start IS NOT NULL AND (dbt_valid_to IS NULL OR dbt_valid_to > next_start))
