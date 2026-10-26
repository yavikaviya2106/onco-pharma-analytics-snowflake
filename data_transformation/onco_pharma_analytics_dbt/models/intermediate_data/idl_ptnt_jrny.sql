WITH ptnt_case AS (
    SELECT
        patient_id,
        dim_hcp_sk,
        dim_prod_sk,
        MAX(hcp_npi)                                      AS hcp_npi,
        MAX(product_id)                                   AS product_id,
        MAX(patient_age)                                  AS patient_age,
        MAX(gender)                                       AS gender,

        MIN(hub_referral_date)                                                AS first_hub_referral_date,
        MAX(CASE WHEN hub_referral_date IS NOT NULL THEN TRUE ELSE FALSE END) AS hub_patient_flag,
        MAX(CASE WHEN hub_enrollment_date IS NOT NULL THEN TRUE ELSE FALSE END) AS hub_enrolled_patient_flag,
        MIN(hub_enrollment_date)                                                AS first_hub_enrollment_date,

        MAX(CASE WHEN hub_referral_date IS NOT NULL THEN TRUE ELSE FALSE END) AS bv_required_flag,
        MAX(CASE WHEN UPPER(benefit_verification_status) 
                IN ('COVERED','NOT_COVERED','NOT COVERED','RESTRICTED') THEN TRUE ELSE FALSE END) AS bv_completed_flag,
        MAX(CASE WHEN UPPER(benefit_verification_status) = 'COVERED' THEN TRUE ELSE FALSE END)AS coverage_confirmed_flag,

        MAX(CASE WHEN hub_pa_required_flag = TRUE THEN TRUE ELSE FALSE END)AS hub_pa_required_flag,
        MAX(CASE WHEN hub_pa_submission_date IS NOT NULL THEN TRUE ELSE FALSE END)AS hub_pa_submitted_flag,
        
        MIN(hub_pa_submission_date)                         AS first_hub_pa_submission_date,
        MIN(CASE WHEN hub_pa_decision_date >= hub_pa_submission_date THEN hub_pa_decision_date END)AS first_hub_pa_decision_date,
        
        MAX(CASE WHEN UPPER(hub_pa_status) = 'APPROVED' THEN TRUE ELSE FALSE END)AS hub_pa_approved_flag,
        MAX(CASE WHEN UPPER(hub_pa_status) = 'DENIED' THEN TRUE ELSE FALSE END)AS hub_pa_denied_flag,
        MAX(CASE WHEN UPPER(hub_pa_status) = 'PENDING' THEN TRUE ELSE FALSE END)AS hub_pa_pending_flag,


        MAX(CASE WHEN pap_eligible_flag = TRUE THEN TRUE ELSE FALSE END)AS pap_eligible_flag,
        MAX(CASE WHEN pap_enrollment_date IS NOT NULL THEN TRUE ELSE FALSE END)AS pap_enrolled_flag,
        MIN(pap_enrollment_date)                          AS first_pap_enrollment_date,
        MAX(CASE WHEN pap_approval_date IS NOT NULL THEN TRUE ELSE FALSE END)AS pap_approved_flag,
        MIN(pap_approval_date)                            AS first_pap_approval_date,

    

        MAX(CASE
                WHEN sp_referral_flag = TRUE
                    OR hub_sp_referral_date IS NOT NULL
                    OR sp_referral_date IS NOT NULL
                THEN TRUE ELSE FALSE END)                   AS sp_referred_flag,
        MIN(
            CASE
                WHEN hub_sp_referral_date IS NOT NULL
                    AND sp_referral_date IS NOT NULL
                    THEN LEAST(hub_sp_referral_date, sp_referral_date)
                WHEN hub_sp_referral_date IS NOT NULL
                    THEN hub_sp_referral_date
                ELSE sp_referral_date
            END)                                              AS first_sp_referral_date,

        MAX(CASE WHEN sp_enrollment_date IS NOT NULL THEN TRUE ELSE FALSE END)AS sp_enrolled_flag,
        MIN(sp_enrollment_date)                          AS first_sp_enrollment_date,

        MAX(CASE WHEN sp_pa_required_flag = TRUE THEN TRUE ELSE FALSE END)
                                                            AS sp_pa_required_flag,
        MAX(CASE WHEN sp_pa_submission_date IS NOT NULL THEN TRUE ELSE FALSE END)
                                                            AS sp_pa_submitted_flag,
        MIN(sp_pa_submission_date)                       AS first_sp_pa_submission_date,
        MIN(CASE WHEN sp_pa_decision_date >= sp_pa_submission_date THEN sp_pa_decision_date END)
                                                            AS first_sp_pa_decision_date,
        MAX(CASE WHEN UPPER(sp_pa_status) = 'APPROVED' THEN TRUE ELSE FALSE END)
                                                            AS sp_pa_approved_flag,
        MAX(CASE WHEN UPPER(sp_pa_status) = 'DENIED' THEN TRUE ELSE FALSE END)
                                                            AS sp_pa_denied_flag,
        MAX(CASE WHEN UPPER(sp_pa_status) = 'PENDING' THEN TRUE ELSE FALSE END)
                                                            AS sp_pa_pending_flag,

        MAX(CASE WHEN hub_referral_date  IS NOT NULL 
                    AND sp_referral_date  IS NOT NULL 
                    AND sp_referral_date >= hub_referral_date
                    THEN TRUE ELSE FALSE END)               AS hub_to_sp_flag
        
    FROM {{ ref('idl_ptnt_cases') }}

    GROUP BY
        patient_id,
        dim_hcp_sk,
        dim_prod_sk
),

txn_summary AS (
    SELECT
        patient_id,
        dim_hcp_sk,
        dim_prod_sk,

        MIN(shipment_date)                               AS first_dispense_date,
        MAX(shipment_date)                               AS last_dispense_date,
        
        MIN(CASE WHEN unit_source = 'SP' THEN shipment_date END)AS first_sp_dispense_date,
        MAX(CASE WHEN unit_source = 'SP' THEN shipment_date END)AS last_sp_dispense_date,
       
        MIN(CASE WHEN unit_source = 'PAP' THEN shipment_date END)AS first_pap_dispense_date,
        MAX(CASE WHEN unit_source = 'PAP' THEN shipment_date END)AS last_pap_dispense_date
    
    FROM {{ ref('idl_ptnt_txn_units') }}

    GROUP BY
        patient_id,
        dim_hcp_sk,
        dim_prod_sk
),

combined AS (
    SELECT
        p.*,

        t.first_dispense_date,
        t.last_dispense_date,

        t.first_sp_dispense_date,
        t.last_sp_dispense_date,

        t.first_pap_dispense_date,
        t.last_pap_dispense_date

    FROM ptnt_case p

    LEFT JOIN txn_summary t
        ON p.patient_id = t.patient_id
        AND p.dim_hcp_sk = t.dim_hcp_sk
        AND p.dim_prod_sk = t.dim_prod_sk
),

derived AS (
    SELECT
        *,

        LEAST_IGNORE_NULLS(
            first_hub_referral_date,
            first_hub_enrollment_date,
            first_sp_referral_date,
            first_dispense_date
        )                                                AS first_observed_date,

        CASE
            WHEN first_hub_pa_submission_date IS NOT NULL
                AND first_hub_pa_decision_date IS NOT NULL
                AND first_hub_pa_decision_date >= first_hub_pa_submission_date
            THEN DATEDIFF(DAY, first_hub_pa_submission_date, first_hub_pa_decision_date)
        END                                              AS hub_pa_decision_days,

        CASE
            WHEN first_sp_pa_submission_date IS NOT NULL
                AND first_sp_pa_decision_date IS NOT NULL
                AND first_sp_pa_decision_date >= first_sp_pa_submission_date
            THEN DATEDIFF(DAY, first_sp_pa_submission_date, first_sp_pa_decision_date)
        END                                              AS sp_pa_decision_days,

        CASE
            WHEN first_hub_referral_date IS NOT NULL
                AND first_sp_referral_date IS NOT NULL
                AND first_sp_referral_date >= first_hub_referral_date
            THEN DATEDIFF(DAY, first_hub_referral_date, first_sp_referral_date)
        END                                             AS hub_to_sp_transition_days,

        CASE
            WHEN first_dispense_date IS NOT NULL THEN TRUE
            ELSE FALSE
        END                                              AS therapy_started_flag,
        first_dispense_date                              AS therapy_start_date,


        CASE WHEN first_pap_dispense_date IS NOT NULL 
            THEN TRUE ELSE FALSE
        END                                             AS pap_patient_flag,

        CASE
            WHEN first_sp_dispense_date IS NOT NULL
            THEN TRUE ELSE FALSE
        END                                             AS commercial_patient_flag,
        
        CASE
            WHEN first_pap_dispense_date IS NOT NULL
                AND first_sp_dispense_date IS NOT NULL
                AND first_sp_dispense_date > first_pap_dispense_date
            THEN TRUE ELSE FALSE
        END                                             AS pap_to_commercial_flag,

        CASE
            WHEN first_pap_dispense_date IS NOT NULL
                AND first_sp_dispense_date IS NOT NULL
                AND first_sp_dispense_date > first_pap_dispense_date
            THEN first_sp_dispense_date
        END                                             AS pap_to_commercial_date,

        CASE
            WHEN first_pap_dispense_date IS NOT NULL
                AND first_sp_dispense_date IS NOT NULL
                AND first_sp_dispense_date > first_pap_dispense_date
            THEN DATEDIFF(DAY,
                first_pap_dispense_date,
                first_sp_dispense_date)
        END                                             AS pap_to_commercial_days,

        CASE
            WHEN first_pap_dispense_date IS NOT NULL
                AND last_pap_dispense_date IS NOT NULL
            THEN DATEDIFF(DAY,
                first_pap_dispense_date,
                last_pap_dispense_date) + 1
        END                                             AS pap_duration_days,

        
        CASE
            WHEN first_hub_referral_date IS NOT NULL
                AND first_dispense_date IS NOT NULL
                AND first_dispense_date >= first_hub_referral_date
            THEN DATEDIFF(DAY, first_hub_referral_date, first_dispense_date)
        END                                              AS time_to_therapy_days

    FROM combined
)

SELECT
    patient_id,
    patient_age,
    gender,
    dim_hcp_sk,
    hcp_npi,
    dim_prod_sk,
    product_id,

    first_observed_date,

    hub_patient_flag,
    first_hub_referral_date,
    hub_enrolled_patient_flag                           AS hub_enrolled_flag,
    first_hub_enrollment_date,

    bv_required_flag,
    bv_completed_flag,
    coverage_confirmed_flag,

    hub_pa_required_flag,
    hub_pa_submitted_flag,
    first_hub_pa_submission_date,
    first_hub_pa_decision_date,
    hub_pa_approved_flag,
    hub_pa_denied_flag,
    hub_pa_pending_flag,
    hub_pa_decision_days,

    pap_eligible_flag,
    pap_enrolled_flag,
    first_pap_enrollment_date,
    pap_approved_flag,
    first_pap_approval_date,

    sp_referred_flag,
    first_sp_referral_date,
    sp_enrolled_flag,
    first_sp_enrollment_date,

    sp_pa_required_flag,
    sp_pa_submitted_flag,
    first_sp_pa_submission_date,
    first_sp_pa_decision_date,
    sp_pa_approved_flag,
    sp_pa_denied_flag,
    sp_pa_pending_flag,
    sp_pa_decision_days,

    hub_to_sp_flag,
    hub_to_sp_transition_days,

    therapy_started_flag,
    therapy_start_date,

    first_dispense_date,
    last_dispense_date,

    first_sp_dispense_date,
    last_sp_dispense_date,

    first_pap_dispense_date,
    last_pap_dispense_date,

    pap_patient_flag,
    commercial_patient_flag,
    pap_to_commercial_flag,
    pap_to_commercial_date,
    pap_to_commercial_days,
    pap_duration_days,

    time_to_therapy_days,

    CASE
        WHEN time_to_therapy_days BETWEEN 0 AND 7 THEN 'WITHIN_1_WEEK'
        WHEN time_to_therapy_days BETWEEN 8 AND 14 THEN '1_TO_2_WEEKS'
        WHEN time_to_therapy_days BETWEEN 15 AND 30 THEN '2_TO_4_WEEKS'
        WHEN time_to_therapy_days BETWEEN 31 AND 60 THEN '1_TO_2_MONTHS'
        WHEN time_to_therapy_days >= 61 THEN 'OVER_2_MONTHS'
    END                                                 AS time_to_therapy_bucket

FROM derived