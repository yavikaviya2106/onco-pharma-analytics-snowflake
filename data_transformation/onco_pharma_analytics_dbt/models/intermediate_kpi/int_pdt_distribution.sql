WITH pdt_dis AS (
    SELECT *
    FROM {{ ref('idl_pdt_distribution') }}
),

terr AS (
    SELECT
        dim_terr_sk,
        territory_id,
        district_id,
        region_id,
        area_id,
        nation_id
    FROM {{ ref('dim_terr_algn') }}
    WHERE is_current = TRUE
),

time_bucket AS (
    SELECT
        NULL AS product_id,
        bucket_type,
        bucket_name,
        bucket_start_date,
        bucket_end_date
    FROM {{ ref('dim_time_bucket') }}

    UNION ALL

    SELECT
        product_id,
        bucket_type,
        bucket_name,
        bucket_start_date,
        bucket_end_date
    FROM {{ ref('dim_pdt_time_bucket') }}
)

SELECT
    pdt_dis.dim_terr_sk AS dim_terr_sk,
    terr.territory_id AS territory_id,
    terr.district_id AS district_id,
    terr.region_id AS region_id,
    terr.area_id AS area_id,
    terr.nation_id AS nation_id,

    pdt_dis.dim_prod_sk AS dim_prod_sk,
    pdt_dis.product_id AS product_id,

    t.bucket_type AS bucket_type,
    t.bucket_name AS bucket_name,
    t.bucket_start_date                                      AS bucket_start_date,
    t.bucket_end_date                                        AS bucket_end_date,

    UPPER(pdt_dis.channel) AS channel,
    pdt_dis.class_of_trade AS class_of_trade,

    COUNT(DISTINCT pdt_dis.outlet_id) AS total_accounts,

    SUM(pdt_dis.sales_units) AS gross_sales_units,

    SUM(pdt_dis.returns_units) AS returns_units,

    SUM(pdt_dis.sales_units)
        - SUM(pdt_dis.returns_units) AS net_units

FROM pdt_dis

LEFT JOIN terr
    ON pdt_dis.dim_terr_sk = terr.dim_terr_sk

INNER JOIN time_bucket t
    ON pdt_dis.week_end_date
        BETWEEN t.bucket_start_date AND t.bucket_end_date
    AND (
        t.product_id IS NULL
        OR pdt_dis.product_id = t.product_id
    )

GROUP BY
    pdt_dis.dim_terr_sk,
    terr.territory_id,
    terr.district_id,
    terr.region_id,
    terr.area_id,
    terr.nation_id,
    pdt_dis.dim_prod_sk,
    pdt_dis.product_id,
    t.bucket_type,
    t.bucket_name,
    t.bucket_start_date,
    t.bucket_end_date,
    UPPER(pdt_dis.channel),
    pdt_dis.class_of_trade