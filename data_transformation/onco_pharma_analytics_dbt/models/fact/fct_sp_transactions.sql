{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'sp_transaction_id',
        merge_exclude_columns = ['dwh_insert_ts'],
        on_schema_change = 'append_new_columns'
    )
}}

WITH sp_src AS (
    SELECT *
    FROM {{ ref('stg_sp_transactions') }}

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
    {{ dbt_utils.generate_surrogate_key(['sp_src.sp_transaction_id']) }} AS fct_sp_txn_sk,

    sp_src.sp_transaction_id                    AS sp_transaction_id,
    sp_src.hub_case_id                          AS hub_case_id,
    sp_src.sp_case_id                           AS sp_case_id,
    
    sp_src.patient_id                           AS patient_id,

    sp_src.hcp_npi                              AS hcp_npi,
    hcp.dim_hcp_sk                              AS dim_hcp_sk,

    sp_src.ndc_code                             AS ndc_code,
    prod.product_id                             AS product_id,
    prod.dim_prod_sk                            AS dim_prod_sk,

    sp_src.transaction_date                     AS transaction_date,
    sp_src.transaction_type                     AS transaction_type,
    sp_src.transaction_status                   AS transaction_status,

    sp_src.rx_number                            AS rx_number,
    sp_src.fill_number                          AS fill_number,

    sp_src.quantity_prescribed                  AS quantity_prescribed,
    sp_src.quantity_dispensed                   AS quantity_dispensed,

    sp_src.unit_of_measure                      AS unit_of_measure,
    sp_src.package_quantity                     AS package_quantity,
    sp_src.package_count                        AS package_count,
    sp_src.units_per_day                        AS units_per_day,

    sp_src.days_supply                          AS days_supply,

    sp_src.shipment_date                        AS shipment_date,
    sp_src.delivery_date                        AS delivery_date,

    sp_src.payer_id                             AS payer_id,
    sp_src.copay_amount                         AS copay_amount,

    sp_src.source_updated_at                    AS source_updated_at,

    {{ current_timestamp_ist() }}               AS dwh_insert_ts,
    {{ current_timestamp_ist() }}               AS dwh_update_ts

FROM sp_src

LEFT JOIN hcp
    ON sp_src.hcp_npi = hcp.hcp_npi
    AND sp_src.transaction_date >= hcp.valid_from
    AND (hcp.valid_to IS NULL
        OR sp_src.transaction_date < hcp.valid_to)

LEFT JOIN prod
    ON sp_src.ndc_code = prod.ndc_code