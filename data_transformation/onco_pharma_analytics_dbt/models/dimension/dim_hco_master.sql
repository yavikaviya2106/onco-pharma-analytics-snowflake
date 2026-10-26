WITH hco_snap AS (
    SELECT
        *,
        -- earliest snapshot version of each onekey_hco_id
        MIN(dbt_valid_from) OVER (PARTITION BY onekey_hco_id) AS first_valid_from
    FROM {{ ref('hco_snapshot') }}
),

addr AS (
    SELECT 
        dim_addr_sk, 
        address_id,
        valid_from,
        valid_to 
    FROM {{ ref('dim_address_master') }}
)

SELECT

    {{ dbt_utils.generate_surrogate_key(['hco_snap.onekey_hco_id', 'hco_snap.dbt_valid_from']) }} AS dim_hco_sk,
    hco_snap.onekey_hco_id                          AS onekey_hco_id,
    
    hco_snap.hco_npi                                AS hco_npi,
    hco_snap.organization_legal_name                AS hco_name,
    hco_snap.doing_business_as_name                 AS hco_business_name,
    hco_snap.organization_short_name                AS hco_short_name,
    
    hco_snap.organization_status                    AS hco_status,
    hco_snap.organization_type                      AS hco_type,
    
    hco_snap.class_of_trade                         AS class_of_trade,
    hco_snap.class_of_trade_level_1                 AS class_of_trade_level_1,
    hco_snap.class_of_trade_level_2                 AS class_of_trade_level_2,
    hco_snap.class_of_trade_level_3                 AS class_of_trade_level_3,
    
    hco_snap.facility_type                          AS facility_type,
    hco_snap.specialty_type                         AS specialty_type,
    
    hco_snap.hospital_flag                          AS hospital_flag,
    hco_snap.medical_group_flag                     AS medical_group_flag,
    hco_snap.clinic_flag                            AS clinic_flag,
    hco_snap.nursing_home_flag                      AS nursing_home_flag,
    hco_snap.pharmacy_flag                          AS pharmacy_flag,
    hco_snap.gpo_flag                               AS gpo_flag,
    hco_snap.idn_flag                               AS idn_flag,
    hco_snap.aco_flag                               AS aco_flag,
    hco_snap.ipa_flag                               AS ipa_flag,

    hco_snap.corporate_parent_onekey_hco_id         AS corporate_parent_onekey_hco_id,
    hco_snap.corporate_parent_name                    AS corporate_parent_name,

    hco_snap.idn_onekey_hco_id                      AS idn_onekey_hco_id,
    hco_snap.idn_name                               AS idn_name,

    hco_snap.primary_address_id                     AS primary_address_id,
    addr.dim_addr_sk                                AS dim_addr_sk,

    hco_snap.secondary_address_id                   AS secondary_address_id,
    hco_snap.tertiary_address_id                    AS tertiary_address_id,
    
    hco_snap.outpatient_flag                        AS outpatient_flag,
    hco_snap.inpatient_flag                         AS inpatient_flag,
    hco_snap.academic_medical_center_flag           AS academic_medical_center_flag,
    hco_snap.teaching_hospital_flag                 AS teaching_hospital_flag,
    
    hco_snap.effective_start_date                   AS effective_start_date,     
    hco_snap.effective_end_date                     AS effective_end_date,       
    
    CASE
        WHEN hco_snap.dbt_valid_from = hco_snap.first_valid_from
        THEN '1900-01-01'::TIMESTAMP_NTZ
        ELSE hco_snap.dbt_valid_from
    END                                             AS valid_from,
    hco_snap.dbt_valid_from                         AS snapshot_valid_from,  -- original value, audit
    hco_snap.dbt_valid_to                           AS valid_to,
    CASE 
        WHEN hco_snap.dbt_valid_to IS NULL THEN TRUE 
            ELSE FALSE 
    END                                             AS is_current

FROM hco_snap

LEFT JOIN addr
    ON hco_snap.primary_address_id = addr.address_id
    AND hco_snap.dbt_valid_from >= addr.valid_from
    AND (addr.valid_to IS NULL
        OR hco_snap.dbt_valid_from < addr.valid_to)