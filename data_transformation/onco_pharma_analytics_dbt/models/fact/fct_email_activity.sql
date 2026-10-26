{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'email_activity_id',
        merge_exclude_columns = ['dwh_insert_ts'],
        on_schema_change = 'append_new_columns'
    )
}}

WITH email AS (
    SELECT *
    FROM {{ ref('stg_email_activity') }}
    
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
),

prod AS (
    SELECT
        dim_prod_sk,
        product_id
    FROM {{ ref('dim_product_master') }}
),

call AS (
    SELECT
        fct_call_act_sk,
        call_id,
        veeva_hcp_id
    FROM {{ ref('fct_call_activity') }}
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['email.email_activity_id']) }} AS fct_email_act_sk,

    email.email_activity_id                 AS email_activity_id,
    email.email_date                        AS email_date,

    COALESCE(email.hcp_id,call.veeva_hcp_id)     AS veeva_hcp_id,
    email.hcp_npi                           AS hcp_npi,
    hcp.dim_hcp_sk                          AS dim_hcp_sk,

    email.rep_id                            AS rep_id,
    rep.dim_rep_sk                          AS dim_rep_sk,

    email.email_type                        AS email_type,
    email.email_direction                   AS email_direction,
    email.email_subject                     AS email_subject,
    email.email_status                      AS email_status,

    email.email_response_status             AS email_response_status,
    email.response_date                     AS response_date,
    email.email_priority                    AS email_priority,

    email.opened_flag                       AS opened_flag,
    email.open_date                         AS open_date,

    email.clicked_flag                      AS clicked_flag,
    email.click_date                        AS click_date,

    email.attachment_flag                   AS attachment_flag,
    email.response_required_flag            AS response_required_flag,

    email.product_id                        AS product_id,
    prod.dim_prod_sk                        AS dim_prod_sk,

    email.related_call_id                   AS related_call_id,
    call.fct_call_act_sk                    AS fct_call_act_sk,

    email.related_event_id                  AS related_event_id,

    email.campaign_id                       AS campaign_id,
    email.email_channel                     AS email_channel,

    email.created_date                      AS created_date,

    email.source_updated_at                 AS source_updated_at,

    {{ current_timestamp_ist() }}           AS dwh_insert_ts,
    {{ current_timestamp_ist() }}           AS dwh_update_ts

FROM email

LEFT JOIN hcp
    ON email.hcp_npi = hcp.hcp_npi
    AND email.email_date >= hcp.valid_from
    AND (hcp.valid_to IS NULL
        OR email.email_date < hcp.valid_to)

LEFT JOIN rep
    ON email.rep_id = rep.rep_id
    AND email.email_date >= rep.valid_from
    AND (rep.valid_to IS NULL
        OR email.email_date < rep.valid_to)

LEFT JOIN prod
    ON email.product_id = prod.product_id

LEFT JOIN call
    ON email.related_call_id = call.call_id