WITH source AS (
    SELECT * FROM {{ ref('raw_veeva_terr_algn') }}
)


SELECT

    NULLIF(TRIM(territory_id), '')                  AS territory_id,
    NULLIF(TRIM(territory_name), '')                AS territory_name,
    NULLIF(TRIM(district_id), '')                   AS district_id,
    NULLIF(TRIM(district_name), '')                 AS district_name,
    NULLIF(TRIM(region_id), '')                     AS region_id,
    NULLIF(TRIM(region_name), '')                   AS region_name,
    NULLIF(TRIM(area_id), '')                       AS area_id,
    NULLIF(TRIM(area_name), '')                     AS area_name,
    NULLIF(TRIM(nation_id), '')                     AS nation_id,
    NULLIF(TRIM(nation_name), '')                   AS nation_name,
    
    TRY_TO_TIMESTAMP_NTZ(source_updated_at::VARCHAR)    AS source_updated_at,
    UPPER(NULLIF(TRIM(source_system), ''))          AS source_system

FROM source
