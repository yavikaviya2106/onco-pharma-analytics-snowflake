{{ config(materialized='table') }}

WITH buckets AS (
    SELECT
        bucket_type,
        bucket_name,
        bucket_start_date,
        bucket_end_date
    FROM {{ ref('dim_time_bucket') }}
    WHERE bucket_start_date IS NOT NULL
        AND bucket_end_date IS NOT NULL
),

journey AS (
    SELECT
        patient_id,
        dim_prod_sk,
        MIN(product_id) AS product_id,
        MIN(first_observed_date) AS first_observed_date,
        MIN(first_hub_referral_date) AS first_hub_referral_date,
        MIN(first_hub_enrollment_date) AS first_hub_enrollment_date,
        MIN(first_sp_referral_date) AS first_sp_referral_date,
        MIN(first_sp_enrollment_date) AS first_sp_enrollment_date,
        MIN(first_pap_enrollment_date) AS first_pap_enrollment_date,
        MIN(first_dispense_date) AS first_dispense_date,
        MIN(therapy_start_date) AS therapy_start_date,
        MIN(pap_to_commercial_date) AS pap_to_commercial_date
    FROM {{ ref('idl_ptnt_jrny') }}
    GROUP BY patient_id, dim_prod_sk
),

fills AS (
    SELECT
        patient_id,
        dim_prod_sk,
        source_transaction_id,
        unit_source,
        fill_date,
        quantity_dispensed,
        coverage_end_date,
        refill_flag,
        channel_refill_flag
    FROM {{ ref('int_ptnt_fills') }}
    WHERE fill_date IS NOT NULL
        AND unit_source IN ('SP', 'PAP')
),

period_events AS (
    SELECT
        j.patient_id,
        j.dim_prod_sk,
        b.bucket_type,
        b.bucket_name,
        b.bucket_start_date,
        b.bucket_end_date,
        IFF(j.first_observed_date BETWEEN b.bucket_start_date AND b.bucket_end_date, 1, 0) AS new_observed_patient,
        IFF(j.first_hub_referral_date BETWEEN b.bucket_start_date AND b.bucket_end_date, 1, 0) AS new_hub_referral,
        IFF(j.first_hub_enrollment_date BETWEEN b.bucket_start_date AND b.bucket_end_date, 1, 0) AS new_hub_enrollment,
        IFF(j.first_sp_referral_date BETWEEN b.bucket_start_date AND b.bucket_end_date, 1, 0) AS new_sp_referral,
        IFF(j.first_sp_enrollment_date BETWEEN b.bucket_start_date AND b.bucket_end_date, 1, 0) AS new_sp_enrollment,
        IFF(j.first_pap_enrollment_date BETWEEN b.bucket_start_date AND b.bucket_end_date, 1, 0) AS new_pap_enrollment,
        IFF(j.first_dispense_date BETWEEN b.bucket_start_date AND b.bucket_end_date, 1, 0) AS new_dispensed_patient,
        IFF(j.therapy_start_date BETWEEN b.bucket_start_date AND b.bucket_end_date, 1, 0) AS new_therapy_patient,
        IFF(j.pap_to_commercial_date BETWEEN b.bucket_start_date AND b.bucket_end_date, 1, 0) AS new_pap_to_commercial_patient,
        IFF(j.first_hub_enrollment_date <= b.bucket_end_date, 1, 0) AS cumulative_hub_enrolled_patient,
        IFF(j.first_dispense_date <= b.bucket_end_date, 1, 0) AS cumulative_dispensed_patient,
        IFF(j.therapy_start_date <= b.bucket_end_date, 1, 0) AS cumulative_therapy_patient
    FROM journey j
    INNER JOIN buckets b
        ON b.bucket_end_date >= j.first_observed_date
        AND b.bucket_start_date <= CURRENT_DATE()
),

period_fills AS (
    SELECT
        f.patient_id,
        f.dim_prod_sk,
        b.bucket_type,
        b.bucket_name,
        b.bucket_start_date,
        b.bucket_end_date,
        COUNT(DISTINCT f.source_transaction_id) AS fill_count,
        COUNT(DISTINCT IFF(f.unit_source = 'SP', f.source_transaction_id, NULL)) AS sp_fill_count,
        COUNT(DISTINCT IFF(f.unit_source = 'PAP', f.source_transaction_id, NULL)) AS pap_fill_count,
        COUNT(DISTINCT IFF(f.refill_flag, f.source_transaction_id, NULL)) AS refill_count,
        COUNT(DISTINCT IFF(f.unit_source = 'SP' AND f.channel_refill_flag, f.source_transaction_id, NULL)) AS sp_channel_refill_count,
        COUNT(DISTINCT IFF(f.unit_source = 'PAP' AND f.channel_refill_flag, f.source_transaction_id, NULL)) AS pap_channel_refill_count,
        SUM(f.quantity_dispensed) AS total_units,
        SUM(IFF(f.unit_source = 'SP', f.quantity_dispensed, 0)) AS sp_units,
        SUM(IFF(f.unit_source = 'PAP', f.quantity_dispensed, 0)) AS pap_units,
        MAX(IFF(f.unit_source = 'SP', 1, 0)) AS sp_dispensed_patient,
        MAX(IFF(f.unit_source = 'PAP', 1, 0)) AS pap_dispensed_patient
    FROM fills f
    INNER JOIN buckets b
        ON f.fill_date BETWEEN b.bucket_start_date AND b.bucket_end_date
        AND b.bucket_start_date <= CURRENT_DATE()
    GROUP BY
        f.patient_id,
        f.dim_prod_sk,
        b.bucket_type,
        b.bucket_name,
        b.bucket_start_date,
        b.bucket_end_date
),

patient_period AS (
    SELECT
        e.*,
        COALESCE(f.fill_count, 0) AS fill_count,
        COALESCE(f.sp_fill_count, 0) AS sp_fill_count,
        COALESCE(f.pap_fill_count, 0) AS pap_fill_count,
        COALESCE(f.refill_count, 0) AS refill_count,
        COALESCE(f.sp_channel_refill_count, 0) AS sp_channel_refill_count,
        COALESCE(f.pap_channel_refill_count, 0) AS pap_channel_refill_count,
        COALESCE(f.total_units, 0) AS total_units,
        COALESCE(f.sp_units, 0) AS sp_units,
        COALESCE(f.pap_units, 0) AS pap_units,
        IFF(COALESCE(f.fill_count, 0) > 0, 1, 0) AS dispensed_patient,
        COALESCE(f.sp_dispensed_patient, 0) AS sp_dispensed_patient,
        COALESCE(f.pap_dispensed_patient, 0) AS pap_dispensed_patient
    FROM period_events e
    LEFT JOIN period_fills f
        ON e.patient_id = f.patient_id
        AND e.dim_prod_sk = f.dim_prod_sk
        AND e.bucket_type = f.bucket_type
        AND e.bucket_name = f.bucket_name
        AND e.bucket_start_date = f.bucket_start_date
        AND e.bucket_end_date = f.bucket_end_date
),

period_aggregate AS (
    SELECT
        dim_prod_sk,
        bucket_type,
        bucket_name,
        bucket_start_date,
        bucket_end_date,
        COUNT(DISTINCT patient_id) AS observed_patient_population,
        SUM(new_observed_patient) AS new_observed_patients,
        SUM(new_hub_referral) AS new_hub_referrals,
        SUM(new_hub_enrollment) AS new_hub_enrollments,
        SUM(new_sp_referral) AS new_sp_referrals,
        SUM(new_sp_enrollment) AS new_sp_enrollments,
        SUM(new_pap_enrollment) AS new_pap_enrollments,
        SUM(new_dispensed_patient) AS new_dispensed_patients,
        SUM(new_therapy_patient) AS new_therapy_patients,
        SUM(new_pap_to_commercial_patient) AS new_pap_to_commercial_patients,
        SUM(cumulative_hub_enrolled_patient) AS cumulative_hub_enrolled_patients,
        SUM(cumulative_dispensed_patient) AS cumulative_dispensed_patients,
        SUM(cumulative_therapy_patient) AS cumulative_therapy_patients,
        SUM(dispensed_patient) AS dispensed_patients,
        SUM(sp_dispensed_patient) AS sp_dispensed_patients,
        SUM(pap_dispensed_patient) AS pap_dispensed_patients,
        SUM(fill_count) AS total_fills,
        SUM(sp_fill_count) AS sp_fills,
        SUM(pap_fill_count) AS pap_fills,
        SUM(refill_count) AS total_refills,
        SUM(sp_channel_refill_count) AS sp_channel_refills,
        SUM(pap_channel_refill_count) AS pap_channel_refills,
        SUM(total_units) AS total_dispensed_units,
        SUM(sp_units) AS sp_units,
        SUM(pap_units) AS pap_units
    FROM patient_period
    GROUP BY
        dim_prod_sk,
        bucket_type,
        bucket_name,
        bucket_start_date,
        bucket_end_date
)

SELECT
    dim_prod_sk                                     AS dim_prod_sk,
    bucket_type                                     AS bucket_type,
    bucket_name                                     AS bucket_name,
    bucket_start_date                               AS bucket_start_date,
    bucket_end_date                                 AS bucket_end_date,
    observed_patient_population                     AS observed_patient_population,
    new_observed_patients                           AS new_observed_patients,
    new_hub_referrals                               AS new_hub_referrals,
    new_hub_enrollments                             AS new_hub_enrollments,
    new_sp_referrals                                AS new_sp_referrals,
    new_sp_enrollments                              AS new_sp_enrollments,
    new_pap_enrollments                             AS new_pap_enrollments,
    new_dispensed_patients                          AS new_dispensed_patients,
    new_therapy_patients                            AS new_therapy_patients,
    new_pap_to_commercial_patients                  AS new_pap_to_commercial_patients,
    cumulative_hub_enrolled_patients                AS cumulative_hub_enrolled_patients,
    cumulative_dispensed_patients                   AS cumulative_dispensed_patients,
    cumulative_therapy_patients                     AS cumulative_therapy_patients,
    dispensed_patients                              AS dispensed_patients,
    sp_dispensed_patients                           AS sp_dispensed_patients,
    pap_dispensed_patients                          AS pap_dispensed_patients,
    total_fills                                     AS total_fills,
    sp_fills                                        AS sp_fills,
    pap_fills                                       AS pap_fills,
    total_refills                                   AS total_refills,
    sp_channel_refills                              AS sp_channel_refills,
    pap_channel_refills                             AS pap_channel_refills,
    total_dispensed_units                           AS total_dispensed_units,
    sp_units                                        AS sp_units,
    pap_units                                       AS pap_units
FROM period_aggregate
