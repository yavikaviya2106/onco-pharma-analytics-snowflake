{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'ddd_record_id',
        merge_exclude_columns = ['dwh_insert_ts'],
        on_schema_change = 'append_new_columns'
    )
}}

WITH ddd AS (
    SELECT *
    FROM {{ ref('stg_drug_distribution_data') }}

    {% if is_incremental() %}
        WHERE source_updated_at >= (
            SELECT COALESCE(
                DATEADD(day, -1, MAX(source_updated_at)),
                '1900-01-01'::TIMESTAMP)
            FROM {{ this }}
        )
    {% endif %}
),

prod AS (
    SELECT
        dim_prod_sk,
        product_id,
        ndc_code
    FROM {{ ref('dim_product_master') }}
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['ddd.ddd_record_id']) }} AS fct_ddd_sk,
    ddd.ddd_record_id                           AS ddd_record_id,

    ddd.outlet_id                               AS outlet_id,
    ddd.account_name                            AS account_name,
    ddd.account_type                            AS account_type,
    ddd.zip_code                                AS zip_code,

    ddd.class_of_trade                          AS class_of_trade,
    ddd.channel                                 AS channel,
    ddd.sub_channel                             AS sub_channel,

    ddd.ndc_code                                AS ndc_code,
    prod.dim_prod_sk                            AS dim_prod_sk,
    prod.product_id                             AS product_id,

    ddd.week_end_date                           AS week_end_date,

    ddd.sales_units                             AS sales_units,
    ddd.standard_units                          AS standard_units,
    ddd.package_units                           AS package_units,
    ddd.returns_units                           AS returns_units,
    
    ddd.source_updated_at                       AS source_updated_at,

    {{ current_timestamp_ist() }}               AS dwh_insert_ts,
    {{ current_timestamp_ist() }}               AS dwh_update_ts

FROM ddd

LEFT JOIN prod
    ON ddd.ndc_code = prod.ndc_code