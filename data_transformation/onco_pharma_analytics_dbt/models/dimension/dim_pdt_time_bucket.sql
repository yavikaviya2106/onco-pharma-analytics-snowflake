WITH reporting_limit AS (
    SELECT {{ get_max_reporting_date() }} AS max_reporting_date
),

weeks AS (
    SELECT DISTINCT
        week_name,
        week_start_date,
        week_end_date
    FROM {{ ref('dim_date') }}
    WHERE date <= {{ get_max_reporting_date() }}
),

pdt AS (
    SELECT
        product_id,
        launch_date
    FROM {{ ref('dim_product_master') }}
    WHERE launch_date IS NOT NULL
      AND UPPER(status) = 'ACTIVE'
)

SELECT
    pdt.product_id,
    'LTD' AS bucket_type,
    'LTD' AS bucket_name,
    pdt.launch_date AS bucket_start_date,
    LEAST(
        weeks.week_end_date,
        r.max_reporting_date
    ) AS bucket_end_date,
    LEAST(
        weeks.week_end_date,
        r.max_reporting_date
    ) AS till_date

FROM pdt
CROSS JOIN reporting_limit r
JOIN weeks
    ON weeks.week_end_date >= pdt.launch_date

WHERE pdt.launch_date <= r.max_reporting_date