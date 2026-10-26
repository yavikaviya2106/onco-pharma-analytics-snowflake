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

rx AS (
    SELECT * FROM {{ ref('fct_rx_sales') }}
),

rx_history AS (
    SELECT
        hcp_npi,
        dim_prod_sk,

        MIN(CASE
                WHEN COALESCE(trx, 0) > 0
                    OR COALESCE(nrx, 0) > 0
                    OR COALESCE(nbrx, 0) > 0
                THEN week_end_date
            END)                                                       AS first_rx_weekend_date,

        MAX(CASE
                WHEN COALESCE(trx, 0) > 0
                    OR COALESCE(nrx, 0) > 0
                    OR COALESCE(nbrx, 0) > 0
                THEN week_end_date
            END)                                                       AS last_rx_weekend_date

    FROM rx

    GROUP BY
        hcp_npi,
        dim_prod_sk
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
),

bucketed_rx AS (
    SELECT
        hcp.dim_hcp_sk                                          AS dim_hcp_sk,
        hcp.hcp_npi                                             AS hcp_npi,

        rx.dim_prod_sk                                          AS dim_prod_sk,
        rx.product_id                                           AS product_id,

        hcp.dim_terr_sk                                         AS dim_terr_sk,
        hcp.territory_id                                        AS territory_id,
        hcp.district_id                                         AS district_id,
        hcp.region_id                                           AS region_id,
        hcp.area_id                                             AS area_id,
        hcp.nation_id                                           AS nation_id,

        t.bucket_type                                           AS bucket_type,
        t.bucket_name                                           AS bucket_name,
        t.bucket_start_date                                     AS bucket_start_date,
        t.bucket_end_date                                       AS bucket_end_date,

        SUM(COALESCE(rx.trx, 0))                                AS trx,
        SUM(COALESCE(rx.nrx, 0))                                AS nrx,
        SUM(COALESCE(rx.nbrx, 0))                               AS nbrx,
        SUM(COALESCE(rx.refill_rx, 0))                          AS refill_rx,

        SUM(COALESCE(rx.trx_units, 0))                          AS trx_units,
        SUM(COALESCE(rx.nrx_units, 0))                          AS nrx_units,
        SUM(COALESCE(rx.nbrx_units, 0))                         AS nbrx_units,

        SUM(COALESCE(rx.market_trx, 0))                         AS market_trx,
        SUM(COALESCE(rx.market_nrx, 0))                         AS market_nrx

    FROM hcp

    INNER JOIN rx
        ON hcp.hcp_npi = rx.hcp_npi

    INNER JOIN time_bucket t
        ON rx.week_end_date BETWEEN t.bucket_start_date AND t.bucket_end_date
            AND (t.product_id IS NULL
                OR rx.product_id = t.product_id)

    GROUP BY
        hcp.dim_hcp_sk,
        hcp.hcp_npi,
        rx.dim_prod_sk,
        rx.product_id,
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
)

SELECT
    bucketed_rx.dim_hcp_sk                                    AS dim_hcp_sk,
    bucketed_rx.hcp_npi                                       AS hcp_npi,

    bucketed_rx.dim_prod_sk                                   AS dim_prod_sk,
    bucketed_rx.product_id                                    AS product_id,

    bucketed_rx.dim_terr_sk                                   AS dim_terr_sk,
    bucketed_rx.territory_id                                  AS territory_id,
    bucketed_rx.district_id                                   AS district_id,
    bucketed_rx.region_id                                     AS region_id,
    bucketed_rx.area_id                                       AS area_id,
    bucketed_rx.nation_id                                     AS nation_id,

    bucketed_rx.bucket_type                                   AS bucket_type,
    bucketed_rx.bucket_name                                   AS bucket_name,
    bucketed_rx.bucket_start_date                             AS bucket_start_date,
    bucketed_rx.bucket_end_date                               AS bucket_end_date,

    rx_history.first_rx_weekend_date                          AS first_rx_weekend_date,
    rx_history.last_rx_weekend_date                           AS last_rx_weekend_date,

    CASE
        WHEN bucketed_rx.trx > 0
            OR bucketed_rx.nrx > 0
            OR bucketed_rx.nbrx > 0
        THEN TRUE
        ELSE FALSE
    END                                                       AS writer_flag,

    CASE
        WHEN rx_history.first_rx_weekend_date BETWEEN bucketed_rx.bucket_start_date
            AND bucketed_rx.bucket_end_date
        THEN TRUE
        ELSE FALSE
    END                                                       AS new_writer_flag,

    bucketed_rx.trx                                           AS trx,
    bucketed_rx.nrx                                           AS nrx,
    bucketed_rx.nbrx                                          AS nbrx,
    bucketed_rx.refill_rx                                     AS refill_rx,

    bucketed_rx.trx_units                                     AS trx_units,
    bucketed_rx.nrx_units                                     AS nrx_units,
    bucketed_rx.nbrx_units                                    AS nbrx_units,

    bucketed_rx.market_trx                                    AS market_trx,
    bucketed_rx.market_nrx                                    AS market_nrx

FROM bucketed_rx

INNER JOIN rx_history
    ON bucketed_rx.hcp_npi = rx_history.hcp_npi
        AND bucketed_rx.dim_prod_sk = rx_history.dim_prod_sk