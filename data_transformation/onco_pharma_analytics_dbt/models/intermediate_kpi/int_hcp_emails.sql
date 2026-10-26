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

email AS (
    SELECT * FROM {{ ref('fct_email_activity') }}
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

    email.dim_prod_sk                                       AS dim_prod_sk,
    email.product_id                                        AS product_id,

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

    COUNT(
        DISTINCT CASE
            WHEN UPPER(email.email_direction) = 'OUTBOUND'
            THEN email.email_activity_id
        END
    )                                                       AS total_emails_sent,

    COUNT(
        DISTINCT CASE
            WHEN UPPER(email.email_direction) = 'OUTBOUND'
                AND UPPER(email.email_status) = 'DELIVERED'
            THEN email.email_activity_id
        END
    )                                                       AS emails_delivered,

    COUNT(
        DISTINCT CASE
            WHEN UPPER(email.email_direction) = 'OUTBOUND'
                AND UPPER(email.email_status) = 'DELIVERED'
                AND email.opened_flag = TRUE
            THEN email.email_activity_id
        END
    )                                                       AS emails_opened,

    COUNT(
        DISTINCT CASE
            WHEN UPPER(email.email_direction) = 'OUTBOUND'
                AND UPPER(email.email_status) = 'DELIVERED'
                AND email.clicked_flag = TRUE
            THEN email.email_activity_id
        END
    )                                                       AS emails_clicked

FROM hcp 

LEFT JOIN email
    ON hcp.hcp_npi = email.hcp_npi

INNER JOIN time_bucket t
    ON email.email_date BETWEEN t.bucket_start_date AND t.bucket_end_date
        AND (t.product_id IS NULL
            OR email.product_id = t.product_id)

GROUP BY 
    hcp.dim_hcp_sk,
    hcp.hcp_npi,
    email.dim_prod_sk,
    email.product_id,
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