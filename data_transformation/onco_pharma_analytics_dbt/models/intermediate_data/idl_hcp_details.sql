WITH hcp AS (
    SELECT * FROM {{ ref('dim_hcp_master') }}
    WHERE is_current = TRUE
),

affln AS (
    SELECT * FROM {{ ref('bridge_hcp_hco_affln') }}
    WHERE UPPER(TRIM(status)) = 'ACTIVE'
),

hco AS (
    SELECT * FROM {{ ref('dim_hco_master') }}
    WHERE is_current = TRUE
),

addr AS (
    SELECT * FROM {{ ref('dim_address_master') }}
    WHERE is_current = TRUE
),

zip_terr AS (
    SELECT * FROM {{ ref('bridge_zip_to_terr') }}
    WHERE is_current = TRUE
),

terr AS (
    SELECT * FROM {{ ref('dim_terr_algn') }}
    WHERE is_current = TRUE
),

target AS (
    SELECT
        hcp_npi,
        target_flag,
        target_segment
    FROM {{ ref('fct_hcp_tgt_list') }}
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY hcp_npi
        ORDER BY effective_from DESC
    ) = 1
)

SELECT
    hcp.dim_hcp_sk                                       AS dim_hcp_sk,
    hcp.onekey_hcp_id                                    AS onekey_hcp_id,
    hcp.hcp_npi                                          AS hcp_npi,
    hcp.full_name                                        AS full_name,
    hcp.gender                                           AS gender,

    hcp.primary_specialty                                AS primary_specialty,

    hcp.professional_status                              AS professional_status,
    hcp.profession_type                                  AS profession_type,

    hcp.prescriber_flag                                  AS prescriber_flag,
    hcp.prescribing_status                               AS prescribing_status,

    hcp.pdrp_flag                                        AS pdrp_flag,
    COALESCE(target.target_flag, FALSE)                  AS target_flag,
    CASE 
        WHEN UPPER(target.target_segment) = 'A' THEN 'Segment-A'
        WHEN UPPER(target.target_segment) = 'B' THEN 'Segment-B'
        WHEN UPPER(target.target_segment) = 'C' THEN 'Segment-C'
        ELSE 'Unsegmented'
    END                                                  AS target_segment,

    hcp.patient_facing_flag                              AS patient_facing_flag,
    hcp.hospital_based_flag                              AS hospital_based_flag,
    hcp.academic_flag                                    AS academic_flag,
    hcp.key_decision_maker_flag                          AS key_decision_maker_flag,
    hcp.key_opinion_leader_flag                          AS key_opinion_leader_flag,

    hcp.sample_eligibility_flag                          AS sample_eligibility_flag,
    hcp.controlled_sample_eligibility                    AS controlled_sample_eligibility,
    hcp.noncontrolled_sample_eligibility                 AS noncontrolled_sample_eligibility,

    hcp.communication_preference                         AS communication_preference,
    hcp.channel_preference                               AS channel_preference,
    hcp.language_preference                              AS language_preference,

    affln.bridge_hcp_hco_sk                              AS bridge_hcp_hco_sk,
    hcp.primary_affiliation_id                           AS primary_affiliation_id,

    hco.dim_hco_sk                                       AS dim_hco_sk,
    hco.onekey_hco_id                                    AS onekey_hco_id,
    hco.hco_npi                                          AS hco_npi,

    addr.dim_addr_sk                                     AS dim_addr_sk,
    addr.address_id                                      AS address_id,

    addr.address_line_1                                  AS address_line_1,
    addr.city                                            AS city,
    addr.state_code                                      AS state_code,
    addr.state_name                                      AS state_name,
    addr.zip_code                                        AS zip_code,
    addr.county_code                                     AS county_code,
    addr.country_name                                    AS country_name,

    terr.dim_terr_sk                                     AS dim_terr_sk,
    terr.territory_id                                    AS territory_id,
    terr.territory_name                                  AS territory_name,

    terr.district_id                                     AS district_id,
    terr.district_name                                   AS district_name,

    terr.region_id                                       AS region_id,
    terr.region_name                                     AS region_name,

    terr.area_id                                         AS area_id,
    terr.area_name                                       AS area_name,

    terr.nation_id                                       AS nation_id,
    terr.nation_name                                     AS nation_name

FROM hcp

LEFT JOIN affln
    ON hcp.primary_affiliation_id = affln.affiliation_id
        AND hcp.onekey_hcp_id = affln.onekey_hcp_id

LEFT JOIN hco
    ON affln.onekey_hco_id = hco.onekey_hco_id

LEFT JOIN addr
    ON COALESCE(NULLIF(affln.address_id, ''), hco.primary_address_id) = addr.address_id

LEFT JOIN zip_terr
    ON LPAD(TRIM(addr.zip_code::VARCHAR), 5, '0') = LPAD(TRIM(zip_terr.zip_code::VARCHAR), 5, '0')

LEFT JOIN terr
    ON zip_terr.territory_id = terr.territory_id

LEFT JOIN target
    ON hcp.hcp_npi = target.hcp_npi