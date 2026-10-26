-- Every qualifying source activity must appear in idl_hcp_touchpoints.
-- "Qualifying" = same filters and same touchpoint_id the model uses.
WITH expected AS (
    SELECT DISTINCT
        'CALL' AS channel_name,
        call_id AS touchpoint_id
    FROM {{ ref('idl_call_activity') }}
    WHERE UPPER(call_status) = 'COMPLETED'

    UNION

    SELECT DISTINCT
        'EMAIL',
        email_activity_id
    FROM {{ ref('fct_email_activity') }}
    WHERE UPPER(email_direction) = 'OUTBOUND'
      AND UPPER(email_status) = 'DELIVERED'

    UNION

    SELECT DISTINCT
        'EVENT',
        att.medical_event_id          -- event touchpoint_id = event id (same as the model)
    FROM {{ ref('fct_med_eve_attendees') }} att
    INNER JOIN {{ ref('dim_med_events') }} eve
        ON att.medical_event_id = eve.medical_event_id
    WHERE UPPER(att.attendance_status) = 'ATTENDED'
),

actual AS (
    SELECT DISTINCT
        UPPER(channel_name) AS channel_name,
        touchpoint_id
    FROM {{ ref('idl_hcp_touchpoints') }}
)

SELECT e.*
FROM expected e
LEFT JOIN actual a
    ON e.channel_name = a.channel_name
   AND e.touchpoint_id = a.touchpoint_id
WHERE a.touchpoint_id IS NULL