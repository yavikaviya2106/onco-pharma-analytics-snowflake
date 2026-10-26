WITH addr_snap AS (
    SELECT
        *,
        -- earliest snapshot version of each address_id
        MIN(dbt_valid_from) OVER (PARTITION BY address_id) AS first_valid_from
    FROM {{ ref('address_snapshot') }}
)


SELECT
    {{ dbt_utils.generate_surrogate_key(['addr_snap.address_id','addr_snap.dbt_valid_from']) }} AS dim_addr_sk,

   addr_snap.address_id                                             AS address_id,
    
   addr_snap.address_line_1                                         AS address_line_1,
   addr_snap.address_line_2                                         AS address_line_2,
   
   addr_snap.city                                                   AS city,
   addr_snap.county_code                                            AS county_code,
   addr_snap.county_name                                            AS county_name,
   addr_snap.state_code                                             AS state_code,
   addr_snap.state_name                                             AS state_name,
   addr_snap.zip_code                                               AS zip_code,
   addr_snap.country_code                                           AS country_code,
   addr_snap.country                                                AS country_name,

   addr_snap.latitude                                               AS latitude,
   addr_snap.longitude                                              AS longitude,

   addr_snap.metro_flag                                             AS metro_flag,
   addr_snap.urban_flag                                             AS urban_rural_flag,
   addr_snap.rural_flag                                             AS rural_flag,

   addr_snap.address_verified_flag                                  AS address_verified_flag,
   addr_snap.address_validation_status                              AS address_validation_status,
   addr_snap.address_effective_date                                 AS address_effective_date,
   addr_snap.address_end_date                                       AS address_end_date,
   addr_snap.last_verified_date                                     AS last_verified_date,
   addr_snap.address_source                                         AS address_source,

   CASE
       WHEN addr_snap.dbt_valid_from = addr_snap.first_valid_from
       THEN '1900-01-01'::TIMESTAMP_NTZ
       ELSE addr_snap.dbt_valid_from
   END                                                              AS valid_from,
   addr_snap.dbt_valid_from                                         AS snapshot_valid_from,  -- original value, audit
   addr_snap.dbt_valid_to                                           AS valid_to,
   CASE 
        WHEN addr_snap.dbt_valid_to IS NULL THEN TRUE ELSE FALSE 
   END                                                             AS is_current

FROM addr_snap