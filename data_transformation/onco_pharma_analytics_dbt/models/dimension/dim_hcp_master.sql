WITH hcp_snap AS (
    SELECT
        *,
        -- earliest snapshot version of each onekey_hcp_id
        MIN(dbt_valid_from) OVER (PARTITION BY onekey_hcp_id) AS first_valid_from
    FROM {{ ref('hcp_snapshot') }}
),

hco AS (
    SELECT
        dim_hco_sk,
        onekey_hco_id,
        valid_from,
        valid_to
    FROM {{ ref('dim_hco_master') }}
),

aff AS (
    SELECT
        bridge_hcp_hco_sk,
        affiliation_id,
        effective_start_date,
        effective_end_date
    FROM {{ ref('bridge_hcp_hco_affln') }}
)

SELECT

    {{ dbt_utils.generate_surrogate_key(['hcp_snap.onekey_hcp_id', 'hcp_snap.dbt_valid_from']) }} AS dim_hcp_sk,
    hcp_snap.onekey_hcp_id                      AS onekey_hcp_id,

    hcp_snap.npi                                AS hcp_npi,
    hcp_snap.full_name                          AS full_name,
    hcp_snap.gender                             AS gender,

    hcp_snap.professional_status                AS professional_status,
    hcp_snap.profession_type                    AS profession_type,
    hcp_snap.credentials                        AS credentials,

    hcp_snap.primary_specialty                  AS primary_specialty,
    hcp_snap.primary_specialty_code             AS primary_specialty_code,
    hcp_snap.secondary_specialty                AS secondary_specialty,
    hcp_snap.sub_specialty                      AS sub_specialty,

    hcp_snap.prescriber_flag                    AS prescriber_flag,
    hcp_snap.prescribing_status                 AS prescribing_status,

    hcp_snap.pdrp_flag                          AS pdrp_flag,
    hcp_snap.patient_facing_flag                AS patient_facing_flag,
    hcp_snap.hospital_based_flag                AS hospital_based_flag,
    hcp_snap.academic_flag                      AS academic_flag,
    hcp_snap.key_decision_maker_flag            AS key_decision_maker_flag,
    hcp_snap.key_opinion_leader_flag            AS key_opinion_leader_flag,
    hcp_snap.sample_eligibility_flag            AS sample_eligibility_flag,
    hcp_snap.controlled_sample_eligibility      AS controlled_sample_eligibility,
    hcp_snap.noncontrolled_sample_eligibility   AS noncontrolled_sample_eligibility,

    hcp_snap.primary_employer_hco_id            AS primary_employer_hco_id,
    hco.dim_hco_sk                              AS dim_hco_sk,

    hcp_snap.primary_affiliation_id             AS primary_affiliation_id,
    aff.bridge_hcp_hco_sk                       AS bridge_hcp_hco_sk,
    hcp_snap.affiliation_count                  AS affiliation_count,

    hcp_snap.communication_preference           AS communication_preference,
    hcp_snap.channel_preference                 AS channel_preference,
    hcp_snap.language_preference                AS language_preference,

   
    CASE
        WHEN hcp_snap.dbt_valid_from = hcp_snap.first_valid_from
        THEN '1900-01-01'::TIMESTAMP_NTZ
        ELSE hcp_snap.dbt_valid_from
    END                                         AS valid_from,
    hcp_snap.dbt_valid_from                     AS snapshot_valid_from,  -- original value, audit
    hcp_snap.dbt_valid_to                       AS valid_to,
    CASE
        WHEN hcp_snap.dbt_valid_to IS NULL THEN TRUE ELSE FALSE
    END                                         AS is_current

FROM hcp_snap

LEFT JOIN hco
    ON hcp_snap.primary_employer_hco_id = hco.onekey_hco_id
    AND hcp_snap.dbt_valid_from >= hco.valid_from
    AND (hco.valid_to IS NULL
            OR hcp_snap.dbt_valid_from < hco.valid_to)

LEFT JOIN aff
    ON hcp_snap.primary_affiliation_id = aff.affiliation_id
    AND hcp_snap.dbt_valid_from >= aff.effective_start_date
    AND (aff.effective_end_date IS NULL
        OR hcp_snap.dbt_valid_from < aff.effective_end_date)