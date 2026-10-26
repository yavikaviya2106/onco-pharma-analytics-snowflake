
WITH source AS (
    SELECT * FROM {{ ref('raw_iqvia_ddd') }}
)

SELECT

    NULLIF(TRIM(ddd_record_id), '')                         AS ddd_record_id,

    NULLIF(TRIM(ddd_account_id), '')                        AS outlet_id,

    {{ normalize_ndc('ndc') }}                              AS ndc_code,
    NULLIF(TRIM(brand_name), '')                            AS brand_name,
    NULLIF(TRIM(generic_name), '')                          AS generic_name,
    NULLIF(TRIM(manufacturer_id), '')                       AS manufacturer_id,
    NULLIF(TRIM(manufacturer_name), '')                     AS manufacturer_name,

    LPAD(NULLIF(TRIM(zip_code::VARCHAR), ''), 5, '0')             AS zip_code,

    NULLIF(TRIM(account_name), '')                          AS account_name,
    UPPER(NULLIF(TRIM(account_type), ''))                   AS account_type,

    NULLIF(TRIM(class_of_trade), '')                        AS class_of_trade,
    UPPER(NULLIF(TRIM(channel), ''))                        AS channel,
    UPPER(NULLIF(TRIM(sub_channel), ''))                    AS sub_channel,

    week_end_date                         AS week_end_date,

    TRY_TO_DECIMAL(sales_units::VARCHAR, 12,0)                   AS sales_units,
    TRY_TO_DECIMAL(standard_units::VARCHAR, 12,0)                AS standard_units,
    TRY_TO_DECIMAL(package_units::VARCHAR, 12,0)                 AS package_units,
    TRY_TO_DECIMAL(returns_units::VARCHAR, 12,0)                 AS returns_units,

    TRY_TO_TIMESTAMP_NTZ(source_updated_at::VARCHAR)            AS source_updated_at,
    UPPER(NULLIF(TRIM(source_system), ''))                  AS source_system

FROM source
