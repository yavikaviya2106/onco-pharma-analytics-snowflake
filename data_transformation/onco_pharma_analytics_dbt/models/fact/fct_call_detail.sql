{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'call_detail_id',
        merge_exclude_columns = ['dwh_insert_ts'],
        on_schema_change = 'append_new_columns'
    )
}}

WITH call_det AS (
    SELECT * FROM {{ ref('stg_call_detail') }}

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

prod AS (
    SELECT
        dim_prod_sk,
        product_id
    FROM {{ ref('dim_product_master') }}
),

key_msg AS (
    SELECT
        dim_key_msg_sk,
        key_message_id
    FROM {{ ref('dim_key_msg_master') }}
)

SELECT

    {{ dbt_utils.generate_surrogate_key(['call_det.call_detail_id']) }} AS fct_call_dtl_sk,
    call_det.call_detail_id             AS call_detail_id,

    call_det.call_id                    AS call_id,
    call.fct_call_act_sk                AS fct_call_act_sk,

    call_det.product_id                 AS product_id,
    prod.dim_prod_sk                    AS dim_prod_sk,
    call_det.product_position           AS product_position,

    call_det.key_message_id             AS key_message_id,
    call_det.message_theme              AS message_theme,

    call_det.detail_type                AS detail_type,
    call_det.detail_priority            AS detail_priority,
    call_det.discussion_flag            AS discussion_flag,
    call_det.presentation_type          AS presentation_type,

    call_det.hcp_reaction               AS hcp_reaction,
    call_det.hcp_response               AS hcp_response,
    call_det.hcp_interest_level         AS hcp_interest_level,
    call_det.objection_flag             AS objection_flag,
    call_det.objection_type             AS objection_type,

    call_det.detail_notes               AS detail_notes,

    call_det.source_updated_at          AS source_updated_at,

    {{ current_timestamp_ist() }}       AS dwh_insert_ts,
    {{ current_timestamp_ist() }}       AS dwh_update_ts

FROM call_det

LEFT JOIN call
    ON call_det.call_id = call.call_id

LEFT JOIN prod
    ON call_det.product_id = prod.product_id

LEFT JOIN key_msg
    ON call_det.key_message_id = key_msg.key_message_id