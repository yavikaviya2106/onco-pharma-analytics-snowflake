{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'sku_id',
        merge_exclude_columns = ['dwh_insert_ts'],
        on_schema_change = 'sync_all_columns'
    )
}}

WITH sku AS (
    SELECT * FROM {{ ref('stg_sku_details') }}

    {% if is_incremental() %}

        WHERE source_updated_at >= (
            SELECT COALESCE(
                DATEADD(day, -1, MAX(source_updated_at)),
                '1900-01-01'::timestamp
            )
            FROM {{ this }}
        )

    {% endif %}
    
)


SELECT

    {{ dbt_utils.generate_surrogate_key(['sku_id']) }} AS dim_sku_sk,
    sku_id,
    
    sku_code,
    description,
    
    ndc_code,
     
    warehouse_uom,
    strength,
    strength_unit,
    pack_type,
    units_per_pack,
    
    dosage_form,
    
    approval_status,
    approved_date,
    
    inventory_status,
    status,

    source_updated_at,

    {{ current_timestamp_ist() }}           AS dwh_insert_ts,
    {{ current_timestamp_ist() }}           AS dwh_update_ts
    
FROM sku
