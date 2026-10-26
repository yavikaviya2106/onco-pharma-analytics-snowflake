{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'brand_id',
        merge_exclude_columns = ['dwh_insert_ts'],
        on_schema_change = 'sync_all_columns'
    )
}}


WITH brand AS (
    SELECT * FROM {{ ref('stg_brand_details') }}

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

    {{ dbt_utils.generate_surrogate_key(['brand_id']) }} AS dim_brand_sk,
    brand_id,
    brand_name,
    
    therapeutic_area,
    
    company_id,
    company_name,
    
    launch_date,

    source_updated_at,

    {{ current_timestamp_ist() }}           AS dwh_insert_ts,
    {{ current_timestamp_ist() }}           AS dwh_update_ts

FROM brand
