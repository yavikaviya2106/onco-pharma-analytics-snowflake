WITH rep_snap AS (
    SELECT
        *,
        -- earliest snapshot version of each rep_id
        MIN(dbt_valid_from) OVER (PARTITION BY rep_id) AS first_valid_from
    FROM {{ ref('field_force_snapshot') }}
)

SELECT
    {{
        dbt_utils.generate_surrogate_key([
            'rep_snap.rep_id',
            'rep_snap.dbt_valid_from'
        ])
    }} AS dim_rep_sk,

    rep_snap.rep_id AS rep_id,
    rep_snap.rep_name AS rep_name,
    rep_snap.rep_role AS rep_role,
    rep_snap.hire_date AS hire_date,
    rep_snap.effective_start_date AS effective_start_date,
    rep_snap.effective_end_date AS effective_end_date,
    rep_snap.rep_status AS rep_status,

    CASE
        WHEN rep_snap.dbt_valid_from = rep_snap.first_valid_from
        THEN '1900-01-01'::TIMESTAMP_NTZ
        ELSE rep_snap.dbt_valid_from
    END AS valid_from,
    rep_snap.dbt_valid_from AS snapshot_valid_from,  -- original value, audit
    rep_snap.dbt_valid_to AS valid_to,
    CASE
        WHEN rep_snap.dbt_valid_to IS NULL THEN TRUE
        ELSE FALSE
    END AS is_current

FROM rep_snap