WITH keys AS (
    SELECT dim_terr_sk, territory_id, dim_prod_sk, product_id, bucket_type, bucket_name, bucket_start_date, bucket_end_date FROM {{ ref('int_hcp_engagements') }}
    UNION
    SELECT dim_terr_sk, territory_id, dim_prod_sk, product_id, bucket_type, bucket_name, bucket_start_date, bucket_end_date FROM {{ ref('int_hcp_rx_metrics') }}
    UNION
    SELECT dim_terr_sk, territory_id, dim_prod_sk, product_id, bucket_type, bucket_name, bucket_start_date, bucket_end_date FROM {{ ref('int_hcp_units') }}
    UNION
    SELECT dim_terr_sk, territory_id, dim_prod_sk, product_id, bucket_type, bucket_name, bucket_start_date, bucket_end_date FROM {{ ref('int_pdt_distribution') }}
),

-- Territory-level HCP universe: independent of product and bucket
hcp_base AS (
    SELECT
        dim_terr_sk,
        COUNT(DISTINCT hcp_npi)                                                AS total_hcps,
        COUNT(DISTINCT CASE WHEN target_flag = TRUE THEN hcp_npi END)          AS target_hcps
    FROM {{ ref('idl_hcp_details') }}
    GROUP BY dim_terr_sk
),

engagements AS (
    SELECT
        eng.dim_terr_sk                                                        AS dim_terr_sk,
        eng.dim_prod_sk                                                        AS dim_prod_sk,
        eng.bucket_type                                                        AS bucket_type,
        eng.bucket_name                                                        AS bucket_name,
        eng.bucket_start_date                                                    AS bucket_start_date,
        eng.bucket_end_date                                                    AS bucket_end_date,
        COUNT(DISTINCT eng.hcp_npi)                                            AS engaged_hcps,
        COUNT(DISTINCT CASE WHEN hcp.target_flag = TRUE THEN eng.hcp_npi END)  AS engaged_target_hcps,
        COALESCE(SUM(eng.total_engagements), 0)                                AS total_engagements,
        COALESCE(SUM(eng.call_engagements), 0)                                 AS call_engagements,
        COALESCE(SUM(eng.email_engagements), 0)                                AS email_engagements,
        COALESCE(SUM(eng.event_engagements), 0)                                AS event_engagements
    FROM {{ ref('int_hcp_engagements') }} eng
    LEFT JOIN {{ ref('idl_hcp_details') }} hcp
        ON  eng.dim_hcp_sk  = hcp.dim_hcp_sk
        AND eng.dim_terr_sk IS NOT DISTINCT FROM hcp.dim_terr_sk
    GROUP BY
        eng.dim_terr_sk, eng.dim_prod_sk, eng.bucket_type, eng.bucket_name, eng.bucket_start_date, eng.bucket_end_date
),

rx AS (
    SELECT
        dim_terr_sk, dim_prod_sk, bucket_type, bucket_name, bucket_start_date, bucket_end_date,
        COUNT(DISTINCT CASE WHEN writer_flag = TRUE THEN dim_hcp_sk END)       AS writer_hcps,
        SUM(trx)                                                               AS trx,
        SUM(nrx)                                                               AS nrx,
        SUM(nbrx)                                                              AS nbrx,
        SUM(refill_rx)                                                         AS refill_rx,
        SUM(trx_units)                                                         AS trx_units,
        SUM(nrx_units)                                                         AS nrx_units,
        SUM(nbrx_units)                                                        AS nbrx_units,
        SUM(market_trx)                                                        AS market_trx,
        SUM(market_nrx)                                                        AS market_nrx
    FROM {{ ref('int_hcp_rx_metrics') }}
    GROUP BY
        dim_terr_sk, dim_prod_sk, bucket_type, bucket_name, bucket_start_date, bucket_end_date
),

patient_units AS (
    SELECT
        dim_terr_sk, dim_prod_sk, bucket_type, bucket_name, bucket_start_date, bucket_end_date,
        SUM(pap_units)                                                         AS pap_units,
        SUM(sp_units)                                                          AS sp_units
    FROM {{ ref('int_hcp_units') }}
    GROUP BY
        dim_terr_sk, dim_prod_sk, bucket_type, bucket_name, bucket_start_date, bucket_end_date
),

distribution AS (
    SELECT
        dim_terr_sk, dim_prod_sk, bucket_type, bucket_name, bucket_start_date, bucket_end_date,
        COUNT(DISTINCT dim_prod_sk)                                            AS distributed_products,
        SUM(total_accounts)                                                    AS total_account_product_combinations,
        SUM(gross_sales_units)                                                 AS gross_distribution_units,
        SUM(returns_units)                                                     AS return_units,
        SUM(net_units)                                                         AS net_distribution_units
    FROM {{ ref('int_pdt_distribution') }}
    GROUP BY
        dim_terr_sk, dim_prod_sk, bucket_type, bucket_name, bucket_start_date, bucket_end_date
)

SELECT
    k.dim_terr_sk                                                              AS dim_terr_sk,
    k.territory_id                                                             AS territory_id,
    k.dim_prod_sk                                                              AS dim_prod_sk,
    k.product_id                                                               AS product_id,
    k.bucket_type                                                              AS bucket_type,
    k.bucket_name                                                              AS bucket_name,
    k.bucket_start_date                                                        AS bucket_start_date,
    k.bucket_end_date                                                          AS bucket_end_date,

    -- HCP coverage
    COALESCE(hb.total_hcps, 0)                                                 AS total_hcps,
    COALESCE(hb.target_hcps, 0)                                                AS target_hcps,
    COALESCE(eg.engaged_hcps, 0)                                               AS engaged_hcps,
    COALESCE(eg.engaged_target_hcps, 0)                                        AS engaged_target_hcps,
    COALESCE(rx.writer_hcps, 0)                                                AS writer_hcps,

    -- engagements
    COALESCE(eg.total_engagements, 0)                                          AS total_engagements,
    COALESCE(eg.call_engagements, 0)                                           AS call_engagements,
    COALESCE(eg.email_engagements, 0)                                          AS email_engagements,
    COALESCE(eg.event_engagements, 0)                                          AS event_engagements,

    -- Rx
    COALESCE(rx.trx, 0)                                                        AS trx,
    COALESCE(rx.nrx, 0)                                                        AS nrx,
    COALESCE(rx.nbrx, 0)                                                       AS nbrx,
    COALESCE(rx.refill_rx, 0)                                                  AS refill_rx,
    COALESCE(rx.trx_units, 0)                                                  AS trx_units,
    COALESCE(rx.nrx_units, 0)                                                  AS nrx_units,
    COALESCE(rx.nbrx_units, 0)                                                 AS nbrx_units,
    COALESCE(rx.market_trx, 0)                                                 AS market_trx,
    COALESCE(rx.market_nrx, 0)                                                 AS market_nrx,

    -- patient units
    COALESCE(pu.pap_units, 0)                                                  AS pap_units,
    COALESCE(pu.sp_units, 0)                                                   AS sp_units,

    -- distribution
    COALESCE(ds.distributed_products, 0)                                       AS distributed_products,
    COALESCE(ds.total_account_product_combinations, 0)                         AS total_account_product_combinations,
    COALESCE(ds.gross_distribution_units, 0)                                   AS gross_distribution_units,
    COALESCE(ds.return_units, 0)                                               AS return_units,
    COALESCE(ds.net_distribution_units, 0)                                     AS net_distribution_units,

    -- rates (NULL when the denominator is 0)
    COALESCE(eg.engaged_hcps, 0)        / NULLIF(hb.total_hcps, 0)             AS hcp_reach_rate,
    COALESCE(eg.engaged_target_hcps, 0) / NULLIF(hb.target_hcps, 0)            AS target_hcp_reach_rate,
    COALESCE(eg.total_engagements, 0)   / NULLIF(eg.engaged_hcps, 0)           AS engagements_per_engaged_hcp,
    COALESCE(rx.writer_hcps, 0)         / NULLIF(hb.total_hcps, 0)             AS writer_rate,
    COALESCE(rx.trx, 0)                 / NULLIF(rx.market_trx, 0)             AS trx_market_share,
    COALESCE(rx.nrx, 0)                 / NULLIF(rx.market_nrx, 0)             AS nrx_market_share,
    COALESCE(ds.return_units, 0)        / NULLIF(ds.gross_distribution_units, 0) AS distribution_return_rate

FROM keys k

LEFT JOIN hcp_base hb
    ON k.dim_terr_sk = hb.dim_terr_sk

LEFT JOIN engagements eg
    ON  k.dim_terr_sk IS NOT DISTINCT FROM eg.dim_terr_sk
    AND k.dim_prod_sk IS NOT DISTINCT FROM eg.dim_prod_sk
    AND k.bucket_type = eg.bucket_type
    AND k.bucket_name = eg.bucket_name
    AND k.bucket_start_date = eg.bucket_start_date
    AND k.bucket_end_date = eg.bucket_end_date

LEFT JOIN rx
    ON  k.dim_terr_sk IS NOT DISTINCT FROM rx.dim_terr_sk
    AND k.dim_prod_sk IS NOT DISTINCT FROM rx.dim_prod_sk
    AND k.bucket_type = rx.bucket_type
    AND k.bucket_name = rx.bucket_name
    AND k.bucket_start_date = rx.bucket_start_date
    AND k.bucket_end_date = rx.bucket_end_date

LEFT JOIN patient_units pu
    ON  k.dim_terr_sk IS NOT DISTINCT FROM pu.dim_terr_sk
    AND k.dim_prod_sk IS NOT DISTINCT FROM pu.dim_prod_sk
    AND k.bucket_type = pu.bucket_type
    AND k.bucket_name = pu.bucket_name
    AND k.bucket_start_date = pu.bucket_start_date
    AND k.bucket_end_date = pu.bucket_end_date

LEFT JOIN distribution ds
    ON  k.dim_terr_sk IS NOT DISTINCT FROM ds.dim_terr_sk
    AND k.dim_prod_sk IS NOT DISTINCT FROM ds.dim_prod_sk
    AND k.bucket_type = ds.bucket_type
    AND k.bucket_name = ds.bucket_name
    AND k.bucket_start_date = ds.bucket_start_date
    AND k.bucket_end_date = ds.bucket_end_date