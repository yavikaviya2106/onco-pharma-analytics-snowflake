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

omni_channel AS (
    SELECT * FROM {{ ref('idl_hcp_touchpoints') }}
),

time_bucket AS (
    SELECT
        NULL                                                    AS product_id,
        bucket_type                                             AS bucket_type,
        bucket_name                                             AS bucket_name,
        bucket_start_date                                       AS bucket_start_date,
        bucket_end_date                                         AS bucket_end_date
    FROM {{ ref('dim_time_bucket') }}

    UNION ALL

    SELECT
        product_id                                              AS product_id,
        bucket_type                                             AS bucket_type,
        bucket_name                                             AS bucket_name,
        bucket_start_date                                       AS bucket_start_date,
        bucket_end_date                                         AS bucket_end_date
    FROM {{ ref('dim_pdt_time_bucket') }}
)

SELECT
    hcp.dim_hcp_sk                                              AS dim_hcp_sk,
    hcp.hcp_npi                                                 AS hcp_npi,

    o.dim_prod_sk                                               AS dim_prod_sk,
    o.product_id                                                AS product_id,

    hcp.dim_terr_sk                                             AS dim_terr_sk,
    hcp.territory_id                                            AS territory_id,
    hcp.district_id                                             AS district_id,
    hcp.region_id                                               AS region_id,
    hcp.area_id                                                 AS area_id,
    hcp.nation_id                                               AS nation_id,

    t.bucket_type                                               AS bucket_type,
    t.bucket_name                                               AS bucket_name,
    t.bucket_start_date                                      AS bucket_start_date,
    t.bucket_end_date                                        AS bucket_end_date,

    COUNT(DISTINCT o.channel_name || '|' || o.touchpoint_id)    AS total_engagements,

    COUNT(
        DISTINCT CASE 
            WHEN UPPER(o.channel_name) = 'CALL'
            THEN o.touchpoint_id
        END
    )                                                           AS call_engagements,

    COUNT(
        DISTINCT CASE 
            WHEN UPPER(o.channel_name) = 'EMAIL'
            THEN o.touchpoint_id
        END
    )                                                           AS email_engagements,

    COUNT(
        DISTINCT CASE 
            WHEN UPPER(o.channel_name) = 'EVENT'
            THEN o.touchpoint_id
        END
    )                                                           AS event_engagements,

    COUNT(
        DISTINCT o.channel_name
    )                                                           AS distinct_channels,

    CASE
        WHEN COUNT(DISTINCT o.channel_name) = 1
        THEN 1
        ELSE 0
    END                                                         AS single_channel_engagement_flag,

    CASE
        WHEN COUNT(DISTINCT o.channel_name) > 1
        THEN 1
        ELSE 0
    END                                                         AS multi_channel_engagement_flag,

    MIN(o.activity_date) AS first_engagement_date,
    MAX(o.activity_date) AS last_engagement_date,
    DATEDIFF(DAY, MAX(o.activity_date), t.bucket_end_date) AS days_since_last_engagement

FROM hcp

INNER JOIN omni_channel o
    ON hcp.hcp_npi = o.hcp_npi

INNER JOIN time_bucket t
    ON o.activity_date BETWEEN t.bucket_start_date AND t.bucket_end_date
        AND (t.product_id IS NULL
            OR o.product_id = t.product_id)

GROUP BY 
    hcp.dim_hcp_sk,
    hcp.hcp_npi,
    o.dim_prod_sk,
    o.product_id,
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