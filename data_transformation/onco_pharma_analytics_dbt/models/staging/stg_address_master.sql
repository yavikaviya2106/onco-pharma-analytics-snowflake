WITH source AS (
    SELECT * FROM {{ ref('raw_iqvia_onekey_address_master') }}
)
    

SELECT

    NULLIF(TRIM(address_id), '')                                    AS address_id,
        
    NULLIF(TRIM(address_line_1), '')                                AS address_line_1,
    NULLIF(TRIM(address_line_2), '')                                AS address_line_2,
    
    NULLIF(TRIM(city), '')                                          AS city,
    TRY_TO_DECIMAL(fips_county_code::VARCHAR, 20,0)                 AS county_code,
    NULLIF(TRIM(county_name), '')                                   AS county_name,
    UPPER(NULLIF(TRIM(state_code), ''))                             AS state_code,
    NULLIF(TRIM(state_name), '')                                    AS state_name,
    LPAD(NULLIF(TRIM(zip_code::VARCHAR), ''), 5, '0')               AS zip_code,
    UPPER(NULLIF(TRIM(country_code), ''))                           AS country_code,
    UPPER(NULLIF(TRIM(country), ''))                                AS country,
    
    TRY_TO_DECIMAL(latitude::VARCHAR, 9,6)                              AS latitude,
    TRY_TO_DECIMAL(longitude::VARCHAR, 10,6)                             AS longitude,

    {{ normalize_flag('urban_flag') }}                              AS urban_flag,
    {{ normalize_flag('rural_flag') }}                              AS rural_flag,
    {{ normalize_flag('metro_flag') }}                              AS metro_flag,
    
    {{ normalize_flag('address_verified_flag') }}                   AS address_verified_flag,
    UPPER(NULLIF(TRIM(address_validation_status), ''))              AS address_validation_status,
    address_effective_date                        AS address_effective_date,
    TRY_TO_DATE(address_end_date::VARCHAR)                              AS address_end_date,   
    last_verified_date                            AS last_verified_date, 
    NULLIF(TRIM(address_source), '')                                AS address_source,  
    
    TRY_TO_TIMESTAMP_NTZ(source_updated_at::VARCHAR)                    AS source_updated_at,
    UPPER(NULLIF(TRIM(source_system), ''))                          AS source_system

FROM source
