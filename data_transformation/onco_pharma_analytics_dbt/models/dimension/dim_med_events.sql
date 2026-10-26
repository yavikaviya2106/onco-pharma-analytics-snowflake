{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'medical_event_id',
        merge_exclude_columns = ['dwh_insert_ts'],
        on_schema_change = 'sync_all_columns'
    )
}}

WITH events AS (
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

disease AS (
    SELECT 
        dim_disease_sk,
        disease_id,
    FROM {{ ref('dim_disease_details') }}
),

indication AS (
    SELECT 
        dim_indication_sk,
        indication_id,
    FROM {{ ref('dim_indication_details') }}
),

prod AS (
    SELECT
        dim_prod_sk,
        product_id
    FROM {{ ref('dim_product_master') }}
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['events.medical_event_id']) }} AS dim_med_eve_sk,
    events.medical_event_id                AS medical_event_id,

    events.event_name                       AS event_name,
    events.event_type                       AS event_type,
    events.event_category                   AS event_category,
    events.event_status                     AS event_status,
    events.event_description                AS event_description,
    events.event_format                     AS event_format,

    events.event_start_date                 AS event_start_date,
    events.event_end_date                   AS event_end_date,
    events.event_start_time                 AS event_start_time,
    events.event_end_time                   AS event_end_time,
    events.timezone                         AS timezone,

    events.venue_name                       AS venue_name,
    events.venue_address                    AS venue_address,
    events.city                             AS city,
    events.state                            AS state,
    events.country                          AS country,

    events.virtual_platform                 AS virtual_platform,
    events.virtual_event_url                AS virtual_event_url,

    events.therapeutic_area                 AS therapeutic_area,
    events.disease_id                       AS disease_id,
    disease.dim_disease_sk                  AS dim_disease_sk,

    events.primary_product_id               AS primary_product_id,
    prod.dim_prod_sk                        AS dim_prod_sk,

    events.indication_id                    AS indication_id,
    indication.dim_indication_sk            AS dim_indication_sk,

    events.sponsor_name                     AS sponsor_name,
    events.organizing_department            AS organizing_department,
    events.event_owner_id                   AS event_owner_id,
    events.event_coordinator                AS event_coordinator,
    events.agency_name                      AS agency_name,

    events.primary_speaker_npi              AS primary_speaker_npi,

    events.compliance_required_flag         AS compliance_required_flag,
    events.compliance_status                AS compliance_status,
    events.approval_status                  AS approval_status,
    events.approval_date                    AS approval_date,
    events.approval_reference_id            AS approval_reference_id,

    events.source_updated_at                AS source_updated_at,

    {{ current_timestamp_ist() }}           AS dwh_insert_ts,
    {{ current_timestamp_ist() }}           AS dwh_update_ts

FROM events

LEFT JOIN disease
    ON events.disease_id = disease.disease_id

LEFT JOIN indication
    ON events.indication_id = indication.indication_id

LEFT JOIN prod
    ON events.primary_product_id = prod.product_id