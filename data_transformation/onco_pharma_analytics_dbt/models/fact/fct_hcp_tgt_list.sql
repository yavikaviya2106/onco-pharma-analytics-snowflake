{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = ['target_list_id', 'hcp_npi', 'effective_from'],
        merge_exclude_columns = ['dwh_insert_ts'],
        on_schema_change = 'append_new_columns'
    )
}}

WITH target AS (
    SELECT * FROM {{ ref('stg_hcp_target_list') }}

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
)

SELECT
    {{ dbt_utils.generate_surrogate_key([
        'target.target_list_id',
        'target.hcp_npi',
        'target.effective_from'
    ]) }}                           AS fct_hcp_target_sk,

    target.target_list_id           AS target_list_id,
    target.target_list_name         AS target_list_name,

    target.hcp_id                   AS veeva_hcp_id,
    target.hcp_npi                  AS hcp_npi,
    hcp.dim_hcp_sk                  AS dim_hcp_sk,

    target.target_flag              AS target_flag,
    target.target_priority          AS target_priority,
    target.target_segment           AS target_segment,
    target.target_rank              AS target_rank,
    target.target_reason            AS target_reason,
    target.target_score             AS target_score,

    target.target_status            AS target_status,
    target.effective_from           AS effective_from,
    target.effective_to             AS effective_to,

    target.source_updated_at        AS source_updated_at,

    {{ current_timestamp_ist() }}   AS dwh_insert_ts,
    {{ current_timestamp_ist() }}   AS dwh_update_ts

FROM target

LEFT JOIN hcp
    ON target.hcp_npi = hcp.hcp_npi
    AND target.effective_from >= hcp.valid_from
    AND (hcp.valid_to IS NULL
        OR target.effective_from < hcp.valid_to)