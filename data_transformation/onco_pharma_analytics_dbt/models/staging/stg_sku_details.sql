WITH source AS (
    SELECT * FROM {{ ref('raw_product_sku_details') }}
)


SELECT

    NULLIF(TRIM(sku_id), '')                            AS sku_id,
    {{ normalize_ndc('ndc_code') }}                     AS ndc_code,
        
    UPPER(NULLIF(TRIM(sku_code), ''))                   AS sku_code,
    NULLIF(TRIM(description), '')                       AS description,
        
    NULLIF(TRIM(warehouse_uom), '')                     AS warehouse_uom,
    TRY_TO_DECIMAL(strength::VARCHAR, 10,2)                  AS strength,
    NULLIF(TRIM(strength_unit), '')                     AS strength_unit,
    NULLIF(TRIM(pack_type), '')                         AS pack_type,
    TRY_TO_DECIMAL(units_per_pack::VARCHAR, 12,0)            AS units_per_pack, 
    NULLIF(TRIM(dosage_form), '')                       AS dosage_form,
        
    UPPER(NULLIF(TRIM(approval_status), ''))            AS approval_status,
    approved_date                     AS approved_date,
    UPPER(NULLIF(TRIM(inventory_status), ''))           AS inventory_status,
    UPPER(NULLIF(TRIM(status), ''))                     AS status,
        
    TRY_TO_TIMESTAMP_NTZ(source_updated_at::VARCHAR)        AS source_updated_at,
    UPPER(NULLIF(TRIM(source_system), ''))              AS source_system

FROM source
