{{ config(severity='error', tags=['quality_gate', 'p0']) }}

WITH distribution_product_mapping AS (

    SELECT DISTINCT
        ndc_code,
        dim_prod_sk
    FROM {{ ref('fct_pdt_distribution') }}
    WHERE ndc_code IS NOT NULL

),

product_validation AS (

    SELECT
        f.ndc_code,
        f.dim_prod_sk,
        COUNT(p.dim_prod_sk) AS candidate_count,
        MAX(p.dim_prod_sk) AS expected_dim_prod_sk

    FROM distribution_product_mapping f

    LEFT JOIN {{ ref('dim_product_master') }} p
        ON f.ndc_code = p.ndc_code

    GROUP BY
        f.ndc_code,
        f.dim_prod_sk

)

SELECT *
FROM product_validation
WHERE
    candidate_count <> 1
    OR expected_dim_prod_sk IS DISTINCT FROM dim_prod_sk