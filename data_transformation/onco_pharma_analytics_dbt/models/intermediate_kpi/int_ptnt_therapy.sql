{% set gap_days = var('therapy_gap_days', 30) %}

WITH jrny AS (
    SELECT * FROM {{ ref('idl_ptnt_jrny') }}
),

-- Grain: one row per patient x product
patient_jrny AS (
    SELECT
        patient_id,
        dim_prod_sk,
        MAX(product_id)                                                  AS product_id,
        CASE WHEN COUNT(DISTINCT dim_hcp_sk) = 1 THEN MAX(dim_hcp_sk) END AS dim_hcp_sk,
        CASE WHEN COUNT(DISTINCT hcp_npi) = 1 THEN MAX(hcp_npi) END       AS hcp_npi,
        MIN(first_observed_date)                                         AS first_observed_date,
        MIN(therapy_start_date)                                          AS therapy_start_date,
        MIN(first_pap_dispense_date)                                     AS first_pap_dispense_date,
        MIN(first_sp_dispense_date)                                      AS first_sp_dispense_date,
        MAX(last_dispense_date)                                          AS last_dispense_date
    FROM jrny
    GROUP BY patient_id, dim_prod_sk
),

-- Transaction-level fills (NOT the bucketed int_ptnt_units model)
units AS (
    SELECT
        patient_id,
        dim_prod_sk,
        source_transaction_id,
        unit_source,
        shipment_date,
        days_supply,
        DATEADD(DAY, days_supply - 1, shipment_date)                     AS coverage_end_date
    FROM {{ ref('idl_ptnt_txn_units') }}
    WHERE unit_source IN ('SP', 'PAP')
      AND shipment_date IS NOT NULL
      AND days_supply > 0
),

ordered_units AS (
    SELECT
        *,
        MAX(coverage_end_date) OVER (
            PARTITION BY patient_id, dim_prod_sk
            ORDER BY shipment_date, source_transaction_id, unit_source
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        )                                                                AS previous_max_coverage_end_date
    FROM units
),

episode_markers AS (
    SELECT
        *,
        CASE
            WHEN previous_max_coverage_end_date IS NULL THEN 1
            WHEN DATEDIFF(DAY, previous_max_coverage_end_date, shipment_date) - 1 > {{ gap_days }} THEN 1
            ELSE 0
        END                                                              AS new_episode_flag
    FROM ordered_units
),

episode_numbered AS (
    SELECT
        *,
        SUM(new_episode_flag) OVER (
            PARTITION BY patient_id, dim_prod_sk
            ORDER BY shipment_date, source_transaction_id, unit_source
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )                                                                AS therapy_episode_number
    FROM episode_markers
),

episodes AS (
    SELECT
        patient_id,
        dim_prod_sk,
        therapy_episode_number,
        MIN(shipment_date)                                               AS episode_start_date,
        MAX(coverage_end_date)                                           AS episode_last_coverage_date
    FROM episode_numbered
    GROUP BY patient_id, dim_prod_sk, therapy_episode_number
),

episode_summary AS (
    SELECT
        patient_id,
        dim_prod_sk,
        COUNT(*)                                                         AS therapy_episode_count,
        MIN(CASE WHEN therapy_episode_number > 1 THEN episode_start_date END) AS first_restart_date,
        MAX(episode_last_coverage_date)                                  AS last_coverage_end_date,
        MAX(CASE WHEN therapy_episode_number = 1 THEN episode_last_coverage_date END) AS first_episode_coverage_end_date,
        MAX_BY(episode_start_date, therapy_episode_number)               AS latest_episode_start_date
    FROM episodes
    GROUP BY patient_id, dim_prod_sk
),

explicit_discontinuation_events AS (
    SELECT patient_id, dim_prod_sk, hub_close_date AS discontinuation_date
    FROM {{ ref('idl_ptnt_cases') }}
    WHERE hub_close_date IS NOT NULL
      AND (UPPER(COALESCE(hub_close_reason, '')) LIKE '%DISCONTINU%'
           OR UPPER(COALESCE(hub_case_status, '')) LIKE '%DISCONTINU%')

    UNION ALL

    SELECT patient_id, dim_prod_sk, sp_close_date AS discontinuation_date
    FROM {{ ref('idl_ptnt_cases') }}
    WHERE sp_close_date IS NOT NULL
      AND (UPPER(COALESCE(sp_close_reason, '')) LIKE '%DISCONTINU%'
           OR UPPER(COALESCE(sp_case_status, '')) LIKE '%DISCONTINU%')
),

explicit_discontinuation AS (
    SELECT
        patient_id,
        dim_prod_sk,
        MIN(discontinuation_date)                                        AS first_discontinuation_date,
        MAX(discontinuation_date)                                        AS latest_discontinuation_date
    FROM explicit_discontinuation_events
    GROUP BY patient_id, dim_prod_sk
),

-- Data cut-off: latest shipment in the data (override with --vars '{data_as_of_date: 2026-09-30}')
data_end AS (
    SELECT
        {% if var('data_as_of_date', none) %}
        TO_DATE('{{ var("data_as_of_date") }}')
        {% else %}
        MAX(shipment_date)
        {% endif %}                                                      AS data_as_of_date
    FROM {{ ref('idl_ptnt_txn_units') }}
),

combined AS (
    SELECT
        j.*,
        e.therapy_episode_count,
        e.first_restart_date,
        e.latest_episode_start_date,
        e.last_coverage_end_date,
        e.first_episode_coverage_end_date,
        x.first_discontinuation_date,
        x.latest_discontinuation_date,
        d.data_as_of_date
    FROM patient_jrny j
    LEFT JOIN episode_summary e
        ON j.patient_id = e.patient_id AND j.dim_prod_sk = e.dim_prod_sk
    LEFT JOIN explicit_discontinuation x
        ON j.patient_id = x.patient_id AND j.dim_prod_sk = x.dim_prod_sk
    CROSS JOIN data_end d
),

status_base AS (
    SELECT
        *,
        COALESCE(last_coverage_end_date, last_dispense_date)             AS coverage_basis_date,
        (therapy_start_date IS NOT NULL)                                 AS therapy_started_flag,
        (latest_discontinuation_date IS NOT NULL)                        AS discontinued_patient_flag,
        (COALESCE(therapy_episode_count, 0) > 1)                         AS restarted_patient_flag,
        (latest_discontinuation_date IS NOT NULL
            AND (latest_episode_start_date IS NULL
                 OR latest_discontinuation_date >= latest_episode_start_date)) AS current_explicit_discontinued_flag,
        COALESCE(
            data_as_of_date <= DATEADD(DAY, {{ gap_days }}, COALESCE(last_coverage_end_date, last_dispense_date)),
            FALSE
        )                                                                AS within_coverage_grace_flag
    FROM combined
),

status_derived AS (
    SELECT
        *,
        (therapy_started_flag AND NOT current_explicit_discontinued_flag AND within_coverage_grace_flag)
                                                                         AS active_patient_flag,
        (therapy_started_flag AND NOT current_explicit_discontinued_flag AND NOT within_coverage_grace_flag)
                                                                         AS inactive_patient_flag,
        (therapy_started_flag)                                           AS new_patient_flag,
        CASE
            WHEN NOT therapy_started_flag THEN 'NOT_STARTED'
            WHEN current_explicit_discontinued_flag THEN 'DISCONTINUED'
            WHEN within_coverage_grace_flag THEN 'ACTIVE'
            ELSE 'INACTIVE'
        END                                                              AS therapy_status,
        CASE
            WHEN therapy_started_flag THEN
                GREATEST(0, DATEDIFF(DAY, therapy_start_date,
                    CASE
                        WHEN current_explicit_discontinued_flag THEN LEAST(latest_discontinuation_date, data_as_of_date)
                        WHEN NOT within_coverage_grace_flag THEN LEAST(coverage_basis_date, data_as_of_date)
                        ELSE data_as_of_date
                    END) + 1)
        END                                                              AS days_on_therapy,
        -- Persistence: start to the earliest of first-episode coverage end, first discontinuation, data cut-off
        CASE
            WHEN therapy_started_flag THEN
                GREATEST(0, DATEDIFF(DAY, therapy_start_date,
                    LEAST(
                        data_as_of_date,
                        COALESCE(first_episode_coverage_end_date, last_dispense_date),
                        COALESCE(CASE WHEN first_discontinuation_date >= therapy_start_date
                                      THEN first_discontinuation_date END, DATE '9999-12-31')
                    )) + 1)
        END                                                              AS persistence_days
    FROM status_base
)

SELECT
    patient_id                                                           AS patient_id,
    dim_hcp_sk                                                           AS dim_hcp_sk,
    hcp_npi                                                              AS hcp_npi,
    dim_prod_sk                                                          AS dim_prod_sk,
    product_id                                                           AS product_id,
    first_observed_date                                                  AS first_observed_date,
    therapy_start_date                                                   AS therapy_start_date,
    first_pap_dispense_date                                              AS first_pap_dispense_date,
    first_sp_dispense_date                                               AS first_sp_dispense_date,
    last_dispense_date                                                   AS last_dispense_date,
    last_coverage_end_date                                               AS last_coverage_end_date,
    data_as_of_date                                                      AS data_as_of_date,
    TRUE                                                                 AS total_patient_flag,
    new_patient_flag                                                     AS new_patient_flag,
    active_patient_flag                                                  AS active_patient_flag,
    inactive_patient_flag                                                AS inactive_patient_flag,
    discontinued_patient_flag                                            AS discontinued_patient_flag,
    restarted_patient_flag                                               AS restarted_patient_flag,
    therapy_started_flag                                                 AS therapy_started_flag,
    therapy_episode_count                                                AS therapy_episode_count,
    first_restart_date                                                   AS first_restart_date,
    first_discontinuation_date                                           AS discontinuation_date,
    latest_discontinuation_date                                          AS latest_discontinuation_date,
    current_explicit_discontinued_flag                                   AS current_explicit_discontinued_flag,
    therapy_status                                                       AS therapy_status,
    days_on_therapy                                                      AS days_on_therapy,
    persistence_days                                                     AS persistence_days,
    COALESCE(persistence_days >= 30, FALSE)                              AS persistent_30_flag,
    COALESCE(persistence_days >= 90, FALSE)                              AS persistent_90_flag,
    COALESCE(persistence_days >= 180, FALSE)                             AS persistent_180_flag,
    COALESCE(persistence_days >= 365, FALSE)                             AS persistent_365_flag,
    CASE WHEN first_discontinuation_date >= therapy_start_date
         THEN DATEDIFF(DAY, therapy_start_date, first_discontinuation_date)
    END                                                                  AS days_to_discontinuation
FROM status_derived