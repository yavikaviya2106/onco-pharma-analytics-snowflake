WITH hcp AS (
    SELECT 
        dim_hcp_sk,
        hcp_npi,
        dim_terr_sk,
        territory_id,
        district_id,
        region_id,
        area_id,
        nation_id
    FROM {{ ref('idl_hcp_details') }}
),

prod_units AS (
    SELECT * FROM {{ ref('idl_ptnt_txn_units') }}
),

time_bucket AS (
    SELECT
        NULL                                                AS product_id,
        bucket_type                                         AS bucket_type,
        bucket_name                                         AS bucket_name,
        bucket_start_date                                   AS bucket_start_date,
        bucket_end_date                                     AS bucket_end_date
    FROM {{ ref('dim_time_bucket') }}

    UNION ALL

    SELECT
        product_id                                          AS product_id,
        bucket_type                                         AS bucket_type,
        bucket_name                                         AS bucket_name,
        bucket_start_date                                   AS bucket_start_date,
        bucket_end_date                                     AS bucket_end_date
    FROM {{ ref('dim_pdt_time_bucket') }}
)

SELECT
    hcp.dim_hcp_sk                                          AS dim_hcp_sk,
    hcp.hcp_npi                                             AS hcp_npi,

    prod_units.dim_prod_sk                                  AS dim_prod_sk,
    prod_units.product_id                                   AS product_id,

    hcp.dim_terr_sk                                         AS dim_terr_sk,
    hcp.territory_id                                        AS territory_id,
    hcp.district_id                                         AS district_id,
    hcp.region_id                                           AS region_id,
    hcp.area_id                                             AS area_id,
    hcp.nation_id                                           AS nation_id,

    t.bucket_type                                           AS bucket_type,
    t.bucket_name                                           AS bucket_name,
    t.bucket_start_date                                      AS bucket_start_date,
    t.bucket_end_date                                        AS bucket_end_date,

    COALESCE(SUM(prod_units.pap_units), 0)                  AS pap_units,
    COALESCE(SUM(prod_units.sp_units), 0)                   AS sp_units

FROM hcp

LEFT JOIN prod_units
    ON hcp.hcp_npi = prod_units.hcp_npi

INNER JOIN time_bucket t
    ON prod_units.shipment_date BETWEEN t.bucket_start_date AND t.bucket_end_date
        AND (t.product_id IS NULL
            OR prod_units.product_id = t.product_id)

GROUP BY 
    hcp.dim_hcp_sk,
    hcp.hcp_npi,
    prod_units.dim_prod_sk,
    prod_units.product_id,
    hcp.dim_terr_sk,
    hcp.territory_id,
    hcp.district_id,
    hcp.region_id,
    hcp.area_id,
    hcp.nation_id,
    t.bucket_type,
    t.bucket_name,
    t.bucket_start_date,
    t.bucket_end_date