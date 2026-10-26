{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'xponent_record_id',
        merge_exclude_columns = ['dwh_insert_ts'],
        on_schema_change = 'append_new_columns'
    )
}}

WITH rx AS (
    SELECT *
    FROM {{ ref('stg_xponent_data') }}

    {% if is_incremental() %}
        WHERE source_updated_at >= (
            SELECT COALESCE(
                DATEADD(day, -1, MAX(source_updated_at)),
                '1900-01-01'::TIMESTAMP
            )
            FROM {{ this }}
        )
    {% endif %}
),

hcp AS (
    SELECT
        dim_hcp_sk,
        hcp_npi,
        valid_from,
        valid_to
    FROM {{ ref('dim_hcp_master') }}
),

prod AS (
    SELECT
        dim_prod_sk,
        product_id,
        ndc_code
    FROM {{ ref('dim_product_master') }}
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['rx.xponent_record_id']) }} AS fct_rx_sk,
    rx.xponent_record_id                    AS xponent_record_id,

    rx.iqvia_hcp_id                         AS iqvia_hcp_id,
    rx.hcp_npi                              AS hcp_npi,
    hcp.dim_hcp_sk                          AS dim_hcp_sk,

    rx.ndc_code                             AS ndc_code,
    prod.dim_prod_sk                        AS dim_prod_sk,
    prod.product_id                         AS product_id,

    rx.week_end_date                        AS week_end_date,

    rx.trx                                  AS trx,
    rx.nrx                                  AS nrx,
    rx.nbrx                                 AS nbrx,
    rx.refill_rx                            AS refill_rx,

    rx.trx_units                            AS trx_units,
    rx.nrx_units                            AS nrx_units,
    rx.nbrx_units                           AS nbrx_units,

    rx.market_trx                           AS market_trx,
    rx.market_nrx                           AS market_nrx,

    rx.source_updated_at                    AS source_updated_at,

    {{ current_timestamp_ist() }}           AS dwh_insert_ts,
    {{ current_timestamp_ist() }}           AS dwh_update_ts

FROM rx

LEFT JOIN hcp
    ON rx.hcp_npi = hcp.hcp_npi
    AND rx.week_end_date >= hcp.valid_from
    AND (hcp.valid_to IS NULL
        OR rx.week_end_date < hcp.valid_to)

LEFT JOIN prod
    ON rx.ndc_code = prod.ndc_code