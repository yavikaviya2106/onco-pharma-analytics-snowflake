{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'call_id',
        merge_exclude_columns = ['dwh_insert_ts'],
        on_schema_change = 'append_new_columns'
    )
}}

WITH call AS (
    SELECT * FROM {{ ref('stg_call_activity') }}

    {% if is_incremental() %}
        WHERE source_updated_at >= (
            SELECT COALESCE(
                        DATEADD(day, -1, MAX(source_updated_at) ),
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

rep AS (
    SELECT
        dim_rep_sk,
        rep_id,
        valid_from,
        valid_to
    FROM {{ ref('dim_field_force_master') }}
)

SELECT

    {{ dbt_utils.generate_surrogate_key(['call.call_id']) }}           AS fct_call_act_sk,

    call.call_id                               AS call_id,
    call.call_date                             AS call_date,

    call.hcp_id                                AS veeva_hcp_id,
    call.hcp_npi                               AS hcp_npi,
    hcp.dim_hcp_sk                             AS dim_hcp_sk,

    call.rep_id                                AS rep_id,
    rep.dim_rep_sk                             AS dim_rep_sk,

    call.call_type                             AS call_type,
    call.call_status                           AS call_status,
    call.call_outcome                          AS call_outcome,
    call.call_duration_minutes                 AS call_duration_minutes,
    call.call_purpose                          AS call_purpose,
    call.call_channel                          AS call_channel,

    call.is_planned_call                       AS is_planned_call,
    call.is_target_hcp                         AS is_target_hcp,
    call.call_sequence                         AS call_sequence,
    call.key_message_presented                 AS key_message_presented,
    call.sample_drop_flag                      AS sample_drop_flag,

    call.follow_up_required                    AS follow_up_required,
    call.follow_up_date                        AS follow_up_date,

    call.location_type                         AS location_type,
    call.location_name                         AS location_name,

    call.parent_call_id                        AS parent_call_id,
    call.follow_up_action                      AS follow_up_action,
    call.next_best_action                      AS next_best_action,

    call.source_updated_at                     AS source_updated_at,

    {{ current_timestamp_ist() }}              AS dwh_insert_ts,
    {{ current_timestamp_ist() }}              AS dwh_update_ts


FROM call

LEFT JOIN hcp
    ON call.hcp_npi = hcp.hcp_npi
    AND call.call_date >= hcp.valid_from
    AND (hcp.valid_to IS NULL
        OR call.call_date < hcp.valid_to)

LEFT JOIN rep
    ON call.rep_id = rep.rep_id
    AND call.call_date >= rep.valid_from
    AND (rep.valid_to IS NULL
        OR call.call_date < rep.valid_to)
