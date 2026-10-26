{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'medical_event_id',
        merge_exclude_columns = ['dwh_insert_ts'],
        on_schema_change = 'append_new_columns'
    )
}}

WITH med_eve AS (
    SELECT * FROM {{ ref('stg_medical_events') }}

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

dim_med_eve AS (
    SELECT
        dim_med_eve_sk,
        medical_event_id
    FROM {{ ref('dim_med_events') }}
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['med_eve.medical_event_id']) }} AS fct_med_eve_sk,
    med_eve.medical_event_id                    AS medical_event_id,
    dim_med_eve.dim_med_eve_sk                  AS dim_med_eve_sk,

    med_eve.planned_attendee_count              AS planned_attendee_count,
    med_eve.actual_attendee_count               AS actual_attendee_count,
    med_eve.target_attendee_count               AS target_attendee_count,
    med_eve.registration_count                  AS registration_count,
    med_eve.event_capacity                      AS event_capacity,

    med_eve.event_budget                        AS event_budget,
    med_eve.actual_event_cost                   AS actual_event_cost,
    med_eve.currency_code                       AS currency_code,

    med_eve.source_updated_at                   AS source_updated_at,

    {{ current_timestamp_ist() }}               AS dwh_insert_ts,
    {{ current_timestamp_ist() }}               AS dwh_update_ts

FROM med_eve

LEFT JOIN dim_med_eve
    ON med_eve.medical_event_id = dim_med_eve.medical_event_id