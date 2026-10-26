WITH hub AS (
    SELECT *
    FROM {{ ref('stg_hub_transactions') }}
),

sp AS (
    SELECT *
    FROM {{ ref('stg_sp_transactions') }}
),

hcp AS (
    SELECT
        dim_hcp_sk,
        hcp_npi
    FROM {{ ref('dim_hcp_master') }}
    WHERE is_current = TRUE
),

prod AS (
    SELECT
        dim_prod_sk,
        product_id,
        ndc_code
    FROM {{ ref('dim_product_master') }}
),

patient_cases AS (
    SELECT
        COALESCE(hub.patient_id, sp.patient_id) AS patient_id,

        hub.hub_case_id AS hub_case_id,
        sp.sp_case_id AS sp_case_id,

        COALESCE(hub.patient_age, sp.patient_age) AS patient_age,
        COALESCE(hub.gender, sp.gender) AS gender,

        COALESCE(hub.hcp_npi, sp.hcp_npi) AS hcp_npi,
        COALESCE(hub.ndc_code, sp.ndc_code) AS ndc_code,

        hub.referral_date AS hub_referral_date,
        hub.hub_enrollment_date AS hub_enrollment_date,
        hub.hub_case_status AS hub_case_status,

        hub.benefit_verification_status AS benefit_verification_status,
        hub.insurance_type AS insurance_type,
        COALESCE(hub.payer_id, sp.payer_id) AS payer_id,

        hub.pa_required_flag AS hub_pa_required_flag,
        hub.pa_submission_date AS hub_pa_submission_date,
        hub.pa_decision_date AS hub_pa_decision_date,
        hub.pa_status AS hub_pa_status,

        sp.pa_required_flag AS sp_pa_required_flag,
        sp.pa_submission_date AS sp_pa_submission_date,
        sp.pa_decision_date AS sp_pa_decision_date,
        sp.pa_status AS sp_pa_status,

        hub.appeal_flag AS appeal_flag,
        hub.appeal_submission_date AS appeal_submission_date,
        hub.appeal_decision AS appeal_decision,

        hub.pap_eligible_flag AS pap_eligible_flag,
        hub.pap_enrollment_date AS pap_enrollment_date,
        hub.pap_approval_date AS pap_approval_date,

        hub.financial_assistance_flag AS hub_financial_assistance_flag,
        sp.financial_assistance_flag AS sp_financial_assistance_flag,
        hub.copay_assistance_flag AS copay_assistance_flag,

        hub.sp_referral_flag AS sp_referral_flag,
        hub.sp_referral_date AS hub_sp_referral_date,

        sp.sp_name AS sp_name,
        sp.sp_referral_date AS sp_referral_date,
        sp.sp_enrollment_date AS sp_enrollment_date,
        sp.insurance_verified_date AS sp_insurance_verified_date,

        sp.assistance_status AS assistance_status,

        hub.hub_close_reason AS hub_close_reason,
        hub.hub_close_date AS hub_close_date,

        sp.sp_case_status AS sp_case_status,
        sp.sp_close_reason AS sp_close_reason,
        sp.sp_close_date AS sp_close_date

    FROM hub

    FULL OUTER JOIN sp
        ON hub.hub_case_id = sp.hub_case_id
)

SELECT
    patient_cases.patient_id AS patient_id,
    patient_cases.hub_case_id AS hub_case_id,
    patient_cases.sp_case_id AS sp_case_id,

    patient_cases.patient_age AS patient_age,
    patient_cases.gender AS gender,

    hcp.dim_hcp_sk AS dim_hcp_sk,
    patient_cases.hcp_npi AS hcp_npi,

    prod.dim_prod_sk AS dim_prod_sk,
    prod.product_id AS product_id,

    patient_cases.hub_referral_date AS hub_referral_date,
    patient_cases.hub_enrollment_date AS hub_enrollment_date,
    patient_cases.hub_case_status AS hub_case_status,

    patient_cases.benefit_verification_status AS benefit_verification_status,
    patient_cases.insurance_type AS insurance_type,
    patient_cases.payer_id AS payer_id,

    patient_cases.hub_pa_required_flag AS hub_pa_required_flag,
    patient_cases.hub_pa_submission_date AS hub_pa_submission_date,
    patient_cases.hub_pa_decision_date AS hub_pa_decision_date,
    patient_cases.hub_pa_status AS hub_pa_status,

    patient_cases.sp_pa_required_flag AS sp_pa_required_flag,
    patient_cases.sp_pa_submission_date AS sp_pa_submission_date,
    patient_cases.sp_pa_decision_date AS sp_pa_decision_date,
    patient_cases.sp_pa_status AS sp_pa_status,

    patient_cases.appeal_flag AS appeal_flag,
    patient_cases.appeal_submission_date AS appeal_submission_date,
    patient_cases.appeal_decision AS appeal_decision,

    patient_cases.pap_eligible_flag AS pap_eligible_flag,
    patient_cases.pap_enrollment_date AS pap_enrollment_date,
    patient_cases.pap_approval_date AS pap_approval_date,

    patient_cases.hub_financial_assistance_flag AS hub_financial_assistance_flag,
    patient_cases.sp_financial_assistance_flag AS sp_financial_assistance_flag,
    patient_cases.copay_assistance_flag AS copay_assistance_flag,

    patient_cases.sp_referral_flag AS sp_referral_flag,
    patient_cases.hub_sp_referral_date AS hub_sp_referral_date,

    patient_cases.sp_name AS sp_name,
    patient_cases.sp_referral_date AS sp_referral_date,
    patient_cases.sp_enrollment_date AS sp_enrollment_date,
    patient_cases.sp_insurance_verified_date AS sp_insurance_verified_date,

    patient_cases.assistance_status AS assistance_status,

    patient_cases.hub_close_reason AS hub_close_reason,
    patient_cases.hub_close_date AS hub_close_date,

    patient_cases.sp_case_status AS sp_case_status,
    patient_cases.sp_close_reason AS sp_close_reason,
    patient_cases.sp_close_date AS sp_close_date

FROM patient_cases

LEFT JOIN hcp
    ON patient_cases.hcp_npi = hcp.hcp_npi

LEFT JOIN prod
    ON patient_cases.ndc_code = prod.ndc_code