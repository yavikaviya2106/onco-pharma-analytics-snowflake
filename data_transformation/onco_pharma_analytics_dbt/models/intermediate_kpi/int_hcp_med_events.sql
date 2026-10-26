WITH hcp AS (
    SELECT 
        dim_hcp_sk,
        hcp_npi,
        dim_terr_sk,
        territory_id,
        district_id,
        region_id,
        area_id,
        nation_id
    FROM {{ ref('idl_hcp_details') }}
),

med_eve AS (
    SELECT 
        medical_event_id,
        event_start_date,
        dim_prod_sk,
        primary_product_id
    FROM {{ ref('dim_med_events') }}
),

attendee AS (
    SELECT * FROM {{ ref('fct_med_eve_attendees') }}
),

time_bucket AS (
    SELECT
        NULL                                                AS product_id,
        bucket_type                                         AS bucket_type,
        bucket_name                                         AS bucket_name,
        bucket_start_date                                   AS bucket_start_date,
        bucket_end_date                                     AS bucket_end_date
    FROM {{ ref('dim_time_bucket') }}

    UNION ALL

    SELECT
        product_id                                          AS product_id,
        bucket_type                                         AS bucket_type,
        bucket_name                                         AS bucket_name,
        bucket_start_date                                   AS bucket_start_date,
        bucket_end_date                                     AS bucket_end_date
    FROM {{ ref('dim_pdt_time_bucket') }}
)

SELECT 
    hcp.dim_hcp_sk                                          AS dim_hcp_sk,
    hcp.hcp_npi                                             AS hcp_npi,

    med_eve.dim_prod_sk                                     AS dim_prod_sk,
    med_eve.primary_product_id                              AS product_id,

    hcp.dim_terr_sk                                         AS dim_terr_sk,
    hcp.territory_id                                        AS territory_id,
    hcp.district_id                                         AS district_id,
    hcp.region_id                                           AS region_id,
    hcp.area_id                                             AS area_id,
    hcp.nation_id                                           AS nation_id,

    t.bucket_type                                           AS bucket_type,
    t.bucket_name                                           AS bucket_name,
    t.bucket_start_date                                      AS bucket_start_date,
    t.bucket_end_date                                        AS bucket_end_date,

    COUNT(DISTINCT attendee.medical_event_id)               AS events_invited,

    COUNT(
        DISTINCT CASE
            WHEN UPPER(attendee.attendance_status) = 'ATTENDED'
            THEN attendee.medical_event_id
        END
    )                                                       AS events_attended,

    COUNT(
        DISTINCT CASE
            WHEN UPPER(attendee.attendee_role) = 'SPEAKER'
                AND UPPER(attendee.attendance_status) = 'ATTENDED'
            THEN attendee.medical_event_id
        END
    )                                                       AS attended_as_speaker,

    COUNT(
        DISTINCT CASE
            WHEN UPPER(attendee.attendee_role) = 'ATTENDEE'
                AND UPPER(attendee.attendance_status) = 'ATTENDED'
            THEN attendee.medical_event_id
        END
    )                                                       AS attended_as_attendee
    
FROM hcp 

LEFT JOIN attendee
    ON hcp.hcp_npi = attendee.hcp_npi

INNER JOIN med_eve
    ON attendee.medical_event_id = med_eve.medical_event_id

INNER JOIN time_bucket t
    ON med_eve.event_start_date BETWEEN t.bucket_start_date AND t.bucket_end_date
        AND (t.product_id IS NULL
            OR med_eve.primary_product_id = t.product_id)

GROUP BY 
    hcp.dim_hcp_sk,
    hcp.hcp_npi,
    med_eve.dim_prod_sk,
    med_eve.primary_product_id,
    hcp.dim_terr_sk,
    hcp.territory_id,
    hcp.district_id,
    hcp.region_id,
    hcp.area_id,
    hcp.nation_id,
    t.bucket_type,
    t.bucket_name,
    t.bucket_start_date,
    t.bucket_end_date