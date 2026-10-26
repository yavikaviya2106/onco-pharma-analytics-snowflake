{% macro get_max_reporting_date() %}

(
    SELECT MAX(max_date)
    FROM (

        SELECT MAX(week_end_date) AS max_date
        FROM {{ ref('stg_xponent_data') }}

        UNION ALL

        SELECT MAX(week_end_date) AS max_date
        FROM {{ ref('stg_drug_distribution_data') }}

    )
)

{% endmacro %}