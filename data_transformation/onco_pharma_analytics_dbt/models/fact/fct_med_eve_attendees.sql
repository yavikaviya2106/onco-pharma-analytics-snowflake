{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'event_attendee_id',
        merge_exclude_columns = ['dwh_insert_ts'],
        on_schema_change = 'append_new_columns'
    )
}}

WITH eve_att AS (
    SELECT *
    FROM {{ ref('stg_med_eve_attendees') }}

    WHERE event_attendee_id IS NOT NULL

    {% if is_incremental() %}
        AND source_updated_at >= (
            SELECT COALESCE(
                DATEADD(day, -1, MAX(source_updated_at)),
                '1900-01-01'::TIMESTAMP
            )
            FROM {{ this }}
        )
    {% endif %}

    -- One row per attendee (latest version) so the MERGE never sees duplicate keys
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY event_attendee_id
        ORDER BY source_updated_at DESC
    ) = 1
),

dim_med_eve AS (
    SELECT
        dim_med_eve_sk,
        medical_event_id,
        event_start_date
    FROM {{ ref('dim_med_events') }}
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
    {{ dbt_utils.generate_surrogate_key(['eve_att.event_attendee_id']) }} AS fct_eve_att_sk,

    -- must exist in the output: it is the merge unique_key
    eve_att.event_attendee_id                   AS event_attendee_id,

    eve_att.medical_event_id                    AS medical_event_id,
    dim_med_eve.dim_med_eve_sk                  AS dim_med_eve_sk,

    eve_att.hcp_npi                             AS hcp_npi,
    hcp.dim_hcp_sk                              AS dim_hcp_sk,

    eve_att.attendee_role                       AS attendee_role,

    eve_att.invitation_date                     AS invitation_date,
    eve_att.invitation_status                   AS invitation_status,
    eve_att.registration_date                   AS registration_date,
    eve_att.registration_status                 AS registration_status,
    eve_att.attendance_status                   AS attendance_status,
    eve_att.attendance_mode                     AS attendance_mode,

    eve_att.check_in_time                       AS check_in_time,
    eve_att.check_out_time                      AS check_out_time,

    eve_att.no_show_flag                        AS no_show_flag,
    eve_att.cancellation_date                   AS cancellation_date,
    eve_att.eligibility_reason                  AS eligibility_reason,

    eve_att.source_updated_at                   AS source_updated_at,

    {{ current_timestamp_ist() }}               AS dwh_insert_ts,
    {{ current_timestamp_ist() }}               AS dwh_update_ts

FROM eve_att

LEFT JOIN dim_med_eve
    ON eve_att.medical_event_id = dim_med_eve.medical_event_id

LEFT JOIN hcp
    ON eve_att.hcp_npi = hcp.hcp_npi
    AND dim_med_eve.event_start_date >= hcp.valid_from
    AND (hcp.valid_to IS NULL
        OR dim_med_eve.event_start_date < hcp.valid_to)

-- Safety net against join fan-out (duplicate events / overlapping SCD ranges)
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY eve_att.event_attendee_id
    ORDER BY dim_med_eve.dim_med_eve_sk, hcp.valid_from DESC NULLS LAST
) = 1