WITH terr_snap AS (
    SELECT
        *,
        -- earliest snapshot version of each territory_id
        MIN(dbt_valid_from) OVER (PARTITION BY territory_id) AS first_valid_from
    FROM {{ ref('terr_hier_snapshot') }}
)


SELECT

    {{ dbt_utils.generate_surrogate_key(['territory_id', 'dbt_valid_from']) }} AS dim_terr_sk,
    territory_id,
    territory_name,
    
    district_id,
    district_name,
    
    region_id,
    region_name,
    
    area_id,
    area_name,
    
    nation_id,
    nation_name,
    
    CASE
        WHEN dbt_valid_from = first_valid_from
        THEN '1900-01-01'::TIMESTAMP_NTZ
        ELSE dbt_valid_from
    END                                            AS valid_from,
    dbt_valid_from                                 AS snapshot_valid_from,  -- original value, audit
    dbt_valid_to                                   AS valid_to,
    CASE 
        WHEN dbt_valid_to IS NULL THEN TRUE ELSE FALSE
    END AS is_current

FROM terr_snap