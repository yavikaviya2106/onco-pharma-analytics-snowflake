WITH zip_terr AS (
    SELECT * FROM {{ ref('zip_to_terr_snapshot') }}
),

versioned AS (
    SELECT
        *,
        MIN(dbt_valid_from) OVER (PARTITION BY zip_code) AS first_valid_from
    FROM zip_terr
)

SELECT
    {{ dbt_utils.generate_surrogate_key([
        'zip_code', 'territory_id', 'dbt_valid_from']) }} AS bridge_zip_terr_sk,

    zip_code,
    city_name,
    state_code,

    territory_id,

    
    CASE
        WHEN dbt_valid_from = first_valid_from
        THEN DATE '1900-01-01'::TIMESTAMP_NTZ
        ELSE dbt_valid_from::DATE
    END AS valid_from,
    dbt_valid_from AS snapshot_valid_from, --Original value
    dbt_valid_to::DATE AS valid_to,
    CASE
        WHEN dbt_valid_to IS NULL THEN TRUE ELSE FALSE
    END AS is_current

FROM versioned