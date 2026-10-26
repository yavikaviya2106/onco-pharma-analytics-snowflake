{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'sample_id',
        merge_exclude_columns = ['dwh_insert_ts'],
        on_schema_change = 'append_new_columns'
    )
}}

WITH sample_dis AS (
    SELECT * FROM {{ ref('stg_sample_disbursed') }}
    
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

call AS (
    SELECT
        fct_call_act_sk,
        call_id
    FROM {{ ref('fct_call_activity') }}
),

call_det AS (
    SELECT
        fct_call_dtl_sk,
        call_detail_id
    FROM {{ ref('fct_call_detail') }}
),

prod AS (
    SELECT
        dim_prod_sk,
        product_id
    FROM {{ ref('dim_product_master') }}
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['sample_dis.sample_id']) }} AS fct_sample_dis_sk,
    sample_dis.sample_id                                AS sample_id,

    sample_dis.call_id                                  AS call_id,
    call.fct_call_act_sk                            AS fct_call_act_sk,

    sample_dis.call_detail_id                           AS call_detail_id,
    call_det.fct_call_dtl_sk                        AS fct_call_dtl_sk,

    sample_dis.product_id                               AS product_id,
    prod.dim_prod_sk                                AS dim_prod_sk,

    sample_dis.sample_lot_number                        AS sample_lot_number,
    sample_dis.sample_quantity                          AS sample_quantity,
    sample_dis.sample_unit                              AS sample_unit,
    sample_dis.sample_type                              AS sample_type,
    sample_dis.sample_status                            AS sample_status,

    sample_dis.disbursement_date                        AS disbursement_date,
    sample_dis.expiration_date                          AS expiration_date,

    sample_dis.signature_captured_flag                  AS signature_captured_flag,
    sample_dis.acknowledgement_flag                     AS acknowledgement_flag,

    sample_dis.return_required_flag                     AS return_required_flag,
    sample_dis.return_date                              AS return_date,
    sample_dis.return_quantity                          AS return_quantity,
    sample_dis.return_reason                            AS return_reason,

    sample_dis.disbursement_reason                      AS disbursement_reason,

    sample_dis.sample_recipient_type                    AS sample_recipient_type,

    sample_dis.notes                                    AS notes,

    sample_dis.source_updated_at                        AS source_updated_at,

    {{ current_timestamp_ist() }}                   AS dwh_insert_ts,
    {{ current_timestamp_ist() }}                   AS dwh_update_ts

FROM sample_dis

LEFT JOIN call
    ON sample_dis.call_id = call.call_id

LEFT JOIN call_det
    ON sample_dis.call_detail_id = call_det.call_detail_id

LEFT JOIN prod
    ON sample_dis.product_id = prod.product_id