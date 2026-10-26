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

call AS (
    SELECT * FROM {{ ref('idl_call_activity') }}
),

time_bucket AS (
    SELECT
        NULL product_id,
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
    hcp.dim_hcp_sk                                                   AS dim_hcp_sk,
    hcp.hcp_npi                                                      AS hcp_npi,

    call.dim_prod_sk                                               AS dim_prod_sk,
    call.product_id                                                AS product_id,

    hcp.dim_terr_sk                                                  AS dim_terr_sk,
    hcp.territory_id                                                 AS territory_id,
    hcp.district_id                                                  AS district_id,
    hcp.region_id                                                    AS region_id,
    hcp.area_id                                                      AS area_id,
    hcp.nation_id                                                    AS nation_id,
  

    t.bucket_type                                                    AS bucket_type,
    t.bucket_name                                                    AS bucket_name,
    t.bucket_start_date                                               AS bucket_start_date,
    t.bucket_end_date                                                 AS bucket_end_date,

    COUNT(DISTINCT call.call_id)                                     AS total_calls,

                                                               
    COUNT(
        DISTINCT CASE
            WHEN UPPER(call.call_status) = 'COMPLETED'
                AND UPPER(call.call_type) = 'F2F'
            THEN call.call_id
        END
    )                                                                AS f2f_calls,

    COUNT(
        DISTINCT CASE
            WHEN UPPER(call.call_status) = 'COMPLETED'
                AND UPPER(call.call_type) = 'VIRTUAL'
            THEN call.call_id
        END
    )                                                                AS virtual_calls,

    COUNT(
        DISTINCT CASE
            WHEN UPPER(call.call_status) = 'COMPLETED'
                AND UPPER(call.call_type) = 'PHONE'
            THEN call.call_id
        END
    )                                                                AS phone_calls,


     COUNT(
        DISTINCT CASE
            WHEN call.sample_drop_flag = TRUE
            THEN call.call_id
        END
    )                                                                AS sample_dropped_calls,

    SUM(CASE
            WHEN call.sample_drop_flag = TRUE
            THEN call.sample_units
        END
    )                                                                AS sample_units

   
FROM hcp 

LEFT JOIN call
    ON hcp.hcp_npi = call.hcp_npi
    

INNER JOIN time_bucket t
    ON call.call_date BETWEEN t.bucket_start_date AND t.bucket_end_date
    AND (t.product_id IS NULL OR call.product_id = t.product_id)

GROUP BY 
    hcp.dim_hcp_sk,
    hcp.hcp_npi,
    call.dim_prod_sk,
    call.product_id,
    hcp.dim_terr_sk,
    hcp.territory_id,
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
    