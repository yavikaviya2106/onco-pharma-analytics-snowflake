{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'hub_pap_transaction_id',
        merge_exclude_columns = ['dwh_insert_ts'],
        on_schema_change = 'append_new_columns'
    )
}}

WITH hub_src AS (
    SELECT *
    FROM {{ ref('stg_hub_transactions') }}

    -- Case-only rows (no transaction) are not transactions: keep them out of the fact
    WHERE hub_pap_transaction_id IS NOT NULL

    {% if is_incremental() %}
        AND source_updated_at >= (
            SELECT COALESCE(
                DATEADD(day, -1, MAX(source_updated_at)),
                '1900-01-01'::TIMESTAMP
            )
            FROM {{ this }}
        )
    {% endif %}

    -- One row per transaction (latest version) so the MERGE never sees duplicate keys
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY hub_pap_transaction_id
        ORDER BY source_updated_at DESC
    ) = 1
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
    {{ dbt_utils.generate_surrogate_key(['hub_src.hub_pap_transaction_id']) }} AS fct_hub_txn_sk,

    hub_src.hub_pap_transaction_id              AS hub_pap_transaction_id,
    hub_src.hub_case_id                         AS hub_case_id,

    hub_src.patient_id                          AS patient_id,

    hub_src.hcp_npi                             AS hcp_npi,
    hcp.dim_hcp_sk                              AS dim_hcp_sk,

    hub_src.ndc_code                            AS ndc_code,
    prod.product_id                             AS product_id,
    prod.dim_prod_sk                            AS dim_prod_sk,

    hub_src.transaction_date                    AS transaction_date,
    hub_src.transaction_type                    AS transaction_type,
    hub_src.transaction_status                  AS transaction_status,

    hub_src.pap_program_id                      AS pap_program_id,

    hub_src.quantity_requested                  AS quantity_requested,
    hub_src.quantity_approved                   AS quantity_approved,
    hub_src.quantity_dispensed                  AS quantity_dispensed,
    hub_src.fill_number                         AS fill_number,

    hub_src.shipment_date                       AS shipment_date,
    hub_src.delivery_date                       AS delivery_date,

    hub_src.unit_of_measure                     AS unit_of_measure,
    hub_src.package_quantity                    AS package_quantity,
    hub_src.package_count                       AS package_count,
    hub_src.days_supply                         AS days_supply,
    hub_src.units_per_day                       AS units_per_day,

    hub_src.pap_reason                          AS pap_reason,
    hub_src.pap_outcome                         AS pap_outcome,

    hub_src.source_updated_at                   AS source_updated_at,

    {{ current_timestamp_ist() }}               AS dwh_insert_ts,
    {{ current_timestamp_ist() }}               AS dwh_update_ts

FROM hub_src

LEFT JOIN hcp
    ON hub_src.hcp_npi = hcp.hcp_npi
    AND hub_src.transaction_date >= hcp.valid_from
    AND (hcp.valid_to IS NULL
        OR hub_src.transaction_date < hcp.valid_to)

LEFT JOIN prod
    ON hub_src.ndc_code = prod.ndc_code

-- Safety net: if a dimension has overlapping SCD rows or duplicate NDCs, the joins
-- would fan out one transaction into several rows. 
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY hub_src.hub_pap_transaction_id
    ORDER BY hcp.valid_from DESC NULLS LAST, prod.dim_prod_sk
) = 1