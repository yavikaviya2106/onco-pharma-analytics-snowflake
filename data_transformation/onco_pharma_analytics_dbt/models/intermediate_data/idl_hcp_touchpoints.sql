WITH call_touchpoints AS (
    SELECT DISTINCT
        fct_call_act_sk AS touchpoint_sk,
        call_id AS touchpoint_id,
        call_date AS activity_date,
        dim_hcp_sk,
        hcp_npi,
        dim_prod_sk,
        product_id,
        'CALL' channel_name
    FROM {{ ref('idl_call_activity') }}
    WHERE UPPER(call_status) = 'COMPLETED'
),

email_touchpoints AS (
    SELECT DISTINCT
        fct_email_act_sk AS touchpoint_sk,
        email_activity_id AS touchpoint_id,
        email_date AS activity_date,
        dim_hcp_sk,
        hcp_npi,
        dim_prod_sk,
        product_id,
        'EMAIL' channel_name
    FROM {{ ref('fct_email_activity') }}
    WHERE UPPER(email_direction) = 'OUTBOUND'
        AND UPPER(email_status) = 'DELIVERED'
),

event_touchpoints AS (
    SELECT DISTINCT
        eve.dim_med_eve_sk AS touchpoint_sk,
        eve.medical_event_id AS touchpoint_id,
        eve.event_start_date AS activity_date,
        att.dim_hcp_sk,
        att.hcp_npi,
        eve.dim_prod_sk,
        eve.primary_product_id AS product_id,
        'EVENT' channel_name
    FROM {{ ref('fct_med_eve_attendees') }} att
    INNER JOIN {{ ref('dim_med_events') }} AS eve
        ON att.medical_event_id = eve.medical_event_id
    WHERE UPPER(att.attendance_status) = 'ATTENDED'
),

unioned AS (
    SELECT * FROM call_touchpoints
    UNION ALL
    SELECT * FROM email_touchpoints
    UNION ALL
    SELECT * FROM event_touchpoints
)

SELECT
    touchpoint_sk AS touchpoint_sk,
    touchpoint_id AS touchpoint_id,
    activity_date AS activity_date,
    dim_hcp_sk AS dim_hcp_sk,
    hcp_npi AS hcp_npi,
    dim_prod_sk AS dim_prod_sk,
    product_id AS product_id,
    channel_name AS channel_name
FROM unioned
