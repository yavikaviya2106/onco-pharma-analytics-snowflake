{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'product_id',
        merge_exclude_columns = ['dwh_insert_ts'],
        on_schema_change = 'sync_all_columns'
    )
}}

WITH product AS (

    SELECT * FROM {{ ref('stg_product_details') }}

    {% if is_incremental() %}

        WHERE source_updated_at >= (
            SELECT COALESCE(
                DATEADD(day, -1, MAX(source_updated_at)),
                '1900-01-01'::TIMESTAMP_NTZ
            )
            FROM {{ this }}
        )

    {% endif %}

),

sku AS (
    SELECT
        dim_sku_sk,
        ndc_code,
        strength,
        strength_unit,
        pack_type,
        dosage_form
    FROM {{ ref('dim_sku_details') }}
),

generic AS (
    SELECT
        dim_generic_sk,
        generic_id
    FROM {{ ref('dim_generic_details') }}
),

brand AS (
    SELECT
        dim_brand_sk,
        brand_id
    FROM {{ ref('dim_brand_details') }}
)

SELECT

    {{ dbt_utils.generate_surrogate_key(['product.product_id']) }}  AS dim_prod_sk,

    product.product_id              AS product_id,

    sku.dim_sku_sk                  AS dim_sku_sk,

    brand.dim_brand_sk              AS dim_brand_sk,
    product.brand_id                AS brand_id,

    generic.dim_generic_sk          AS dim_generic_sk,
    product.generic_id              AS generic_id,

    product.product_name            AS product_name,
    sku.ndc_code                    AS ndc_code,

    COALESCE(product.strength, sku.strength)                AS strength,
    COALESCE(product.strength_unit, sku.strength_unit)      AS strength_unit,

    COALESCE(product.dosage_form, sku.dosage_form)          AS dosage_form,

    product.route_of_administration                         AS route_of_administration,

    COALESCE(product.pack_type, sku.pack_type)              AS pack_type,

    product.pack_size                                       AS pack_size,

    product.launch_date                                     AS launch_date,
    product.status                                          AS status,

    product.source_updated_at                               AS source_updated_at,

    {{ current_timestamp_ist() }}                           AS dwh_insert_ts,
    {{ current_timestamp_ist() }}                           AS dwh_update_ts

FROM product

LEFT JOIN brand
    ON product.brand_id = brand.brand_id

LEFT JOIN generic
    ON product.generic_id = generic.generic_id

LEFT JOIN sku
    ON product.ndc_code = sku.ndc_code