WITH affln AS (
    SELECT * FROM {{ ref('stg_hcp_hco_affiliation') }}
)


SELECT

    {{ dbt_utils.generate_surrogate_key(['affiliation_id']) }} AS bridge_hcp_hco_sk,
    affiliation_id,

    onekey_hcp_id,
    onekey_hco_id,
    address_id,

    primary_affiliation_flag,
    best_affiliation_flag,
    effective_start_date,
    effective_end_date,
    status,

    relationship_type,
    affiliation_type,
    affiliation_sub_type,
    affiliation_role,
    affiliation_rank,
    employment_flag,
    employment_status,

    department_at_hco,
    specialty_at_hco,
    
    practice_location_flag,
    hospital_affiliation_flag,
    medical_group_affiliation_flag,
    idn_affiliation_flag,
    gpo_affiliation_flag,
    corporate_parent_affiliation_flag,
    out_of_state_flag,
    source_type,
    verification_date

FROM affln



