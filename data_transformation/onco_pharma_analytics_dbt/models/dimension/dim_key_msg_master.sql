{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'key_message_id',
        merge_exclude_columns = ['dwh_insert_ts'],
        on_schema_change = 'sync_all_columns'
    )
}}

WITH key_msg AS (
    SELECT * FROM {{ ref('stg_key_messages') }} 

    {% if is_incremental() %}

        WHERE source_updated_at >= (
            SELECT COALESCE(
                DATEADD(day, -1, MAX(source_updated_at)),
                '1900-01-01'::timestamp
            )
            FROM {{ this }}
        )

    {% endif %} 
),

product AS (
    SELECT
        dim_prod_sk,
        product_id
    FROM {{ ref('dim_product_master') }}
)

SELECT

    {{ dbt_utils.generate_surrogate_key(['key_msg.key_message_id']) }} AS dim_key_msg_sk,

    key_msg.key_message_id          AS key_message_id,
    
    product.dim_prod_sk             AS dim_prod_sk,
    key_msg.product_id              AS product_id,
    
    key_msg.message_title           AS message_title,
    key_msg.message_text            AS message_text,
    key_msg.message_type            AS message_type,
    
    key_msg.therapeutic_area        AS therapeutic_area,
    key_msg.indication              AS indication,
    key_msg.target_specialty        AS target_specialty,
    key_msg.priority                AS priority,
    key_msg.sequence                AS sequence,
    
    key_msg.content_version         AS content_version,
    key_msg.objection_handling      AS objection_handling,
    key_msg.source_reference        AS source_reference,
    
    key_msg.approval_status         AS approval_status,
    key_msg.approved_date           AS approved_date,
    
    key_msg.effective_start_date    AS effective_start_date,
    key_msg.effective_end_date      AS effective_end_date,

    key_msg.source_updated_at       AS source_updated_at,

    {{ current_timestamp_ist() }}   AS dwh_insert_ts,
    {{ current_timestamp_ist() }}   AS dwh_update_ts

FROM key_msg

LEFT JOIN product
    ON key_msg.product_id = product.product_id