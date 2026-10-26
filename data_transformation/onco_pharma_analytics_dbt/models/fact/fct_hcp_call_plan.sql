{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'call_plan_id',
        merge_exclude_columns = ['dwh_insert_ts'],
        on_schema_change = 'append_new_columns'
    )
}}

WITH call_plan AS (
    SELECT *
    FROM {{ ref('stg_hcp_call_plan') }}

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

rep AS (
    SELECT
        dim_rep_sk,
        rep_id,
        valid_from,
        valid_to
    FROM {{ ref('dim_field_force_master') }}
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['call_plan.call_plan_id']) }} AS fct_call_plan_sk,

    call_plan.call_plan_id                      AS call_plan_id,

    call_plan.cycle_id                          AS cycle_id,
    call_plan.cycle_name                        AS cycle_name,

    call_plan.rep_id                            AS rep_id,
    rep.dim_rep_sk                              AS dim_rep_sk,

    call_plan.hcp_id                            AS veeva_hcp_id,
    call_plan.hcp_npi                           AS hcp_npi,
    hcp.dim_hcp_sk                              AS dim_hcp_sk,

    call_plan.target_flag                       AS target_flag,
    call_plan.target_priority                   AS target_priority,

    call_plan.min_call_frequency                AS min_call_frequency,
    call_plan.planned_calls                     AS planned_calls,
    call_plan.max_call_frequency                AS max_call_frequency,

    call_plan.call_plan_start_date              AS call_plan_start_date,
    call_plan.call_plan_end_date                AS call_plan_end_date,

    call_plan.plan_created_date                 AS plan_created_date,
    call_plan.plan_approved_by                  AS plan_approved_by,

    call_plan.source_updated_at                 AS source_updated_at,

    {{ current_timestamp_ist() }}               AS dwh_insert_ts,
    {{ current_timestamp_ist() }}               AS dwh_update_ts

FROM call_plan

LEFT JOIN hcp
    ON call_plan.hcp_npi = hcp.hcp_npi
    AND call_plan.call_plan_start_date >= hcp.valid_from
    AND (hcp.valid_to IS NULL
        OR call_plan.call_plan_start_date < hcp.valid_to)

LEFT JOIN rep
    ON call_plan.rep_id = rep.rep_id
    AND call_plan.call_plan_start_date >= rep.valid_from
    AND (rep.valid_to IS NULL
        OR call_plan.call_plan_start_date < rep.valid_to)

