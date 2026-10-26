WITH source AS (
    SELECT * FROM {{ ref('raw_veeva_zip_to_terr') }}
)

SELECT

    NULLIF(TRIM(zip_code::STRING), '')              AS zip_code,
    NULLIF(TRIM(city_name), '')                     AS city_name,
    UPPER(NULLIF(TRIM(state_code), ''))             AS state_code,
    NULLIF(TRIM(territory_id), '')                  AS territory_id,
    
    TRY_TO_TIMESTAMP_NTZ(source_updated_at::VARCHAR)    AS source_updated_at,
    UPPER(NULLIF(TRIM(source_system), ''))          AS source_system

FROM source
