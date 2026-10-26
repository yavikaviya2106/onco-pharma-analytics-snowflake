WITH rep_terr AS (
    SELECT * FROM {{ ref('stg_field_force_terr_assignment') }}
)

SELECT
    {{
        dbt_utils.generate_surrogate_key([
            'rep_terr.rep_id',
            'rep_terr.assignment_slot',
            'rep_terr.assignment_start_date'
        ])
    }} AS bridge_rep_terr_sk,

    rep_terr.rep_id                     AS rep_id,
    rep_terr.territory_id               AS territory_id,
    rep_terr.assignment_slot            AS assignment_slot,

    rep_terr.assignment_start_date      AS assignment_start_date,
    rep_terr.assignment_end_date        AS assignment_end_date,

    rep_terr.is_active                  AS is_active,

    rep_terr.source_updated_at          AS source_updated_at,
    rep_terr.source_system              AS source_system

FROM rep_terr