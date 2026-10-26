WITH source AS (
    SELECT *
    FROM {{ ref('raw_internal_field_force_terr_assignment') }}
)

SELECT
    NULLIF(TRIM(rep_id), '')                     AS rep_id,

    NULLIF(TRIM(territory_id), '')               AS territory_id,

    UPPER(NULLIF(TRIM(assignment_slot), ''))     AS assignment_slot,

    TRY_TO_DATE(assignment_start_date::VARCHAR)  AS assignment_start_date,

    TRY_TO_DATE(assignment_end_date::VARCHAR)    AS assignment_end_date,

    {{ normalize_flag('is_active') }}            AS is_active,

    TRY_TO_TIMESTAMP_NTZ(source_updated_at::VARCHAR)  AS source_updated_at,

    UPPER(NULLIF(TRIM(source_system), ''))       AS source_system

FROM source