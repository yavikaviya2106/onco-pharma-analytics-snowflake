{{ config(severity='error', tags=['quality_gate', 'p0']) }}

WITH historical_validation AS (

    SELECT
        f.xponent_record_id,
        f.hcp_npi,
        f.week_end_date,
        f.dim_hcp_sk,
        COUNT(h.dim_hcp_sk) AS matching_versions,
        MAX(h.dim_hcp_sk) AS historical_hcp_sk

    FROM {{ ref('fct_rx_sales') }} f

    LEFT JOIN {{ ref('dim_hcp_master') }} h
        ON f.hcp_npi = h.hcp_npi
        AND f.week_end_date >= h.valid_from
        AND (
            f.week_end_date < h.valid_to
            OR h.valid_to IS NULL
        )

    WHERE
        f.hcp_npi IS NOT NULL
        AND f.week_end_date IS NOT NULL

    GROUP BY
        f.xponent_record_id,
        f.hcp_npi,
        f.week_end_date,
        f.dim_hcp_sk

)

SELECT *
FROM historical_validation

WHERE
    matching_versions <> 1
    OR historical_hcp_sk IS DISTINCT FROM dim_hcp_sk