WITH pdt_dis AS (
    SELECT * FROM {{ ref('fct_pdt_distribution') }}
),

zip_terr AS (
    SELECT 
        zip_code,
        territory_id,
        valid_from,
        valid_to
    FROM {{ ref('bridge_zip_to_terr') }}
),

terr AS (
    SELECT
        dim_terr_sk,
        territory_id,
        valid_from,
        valid_to
    FROM {{ ref('dim_terr_algn') }}
),

prod AS (
    SELECT
        dim_prod_sk,
        product_id,
        ndc_code
    FROM {{ ref('dim_product_master') }}
)



SELECT
    pdt_dis.ddd_record_id                           AS ddd_record_id,

    pdt_dis.outlet_id                               AS outlet_id,
    pdt_dis.account_name                            AS account_name,
    pdt_dis.account_type                            AS account_type,

    pdt_dis.class_of_trade                          AS class_of_trade,
    pdt_dis.channel                                 AS channel,
    pdt_dis.sub_channel                             AS sub_channel,

    terr.dim_terr_sk                            AS dim_terr_sk,
    terr.territory_id                           AS territory_id,

    prod.dim_prod_sk                            AS dim_prod_sk,
    prod.product_id                             AS product_id,

    pdt_dis.week_end_date                           AS week_end_date,

    pdt_dis.sales_units                             AS sales_units,
    pdt_dis.standard_units                          AS standard_units,
    pdt_dis.package_units                           AS package_units,
    pdt_dis.returns_units                           AS returns_units

FROM pdt_dis

LEFT JOIN zip_terr
    ON LPAD(TRIM(pdt_dis.zip_code::VARCHAR), 5, '0') = LPAD(TRIM(zip_terr.zip_code::VARCHAR), 5, '0')
    AND pdt_dis.week_end_date >= zip_terr.valid_from::DATE
    AND (zip_terr.valid_to IS NULL OR pdt_dis.week_end_date < zip_terr.valid_to::DATE)

LEFT JOIN terr
    ON zip_terr.territory_id = terr.territory_id
    AND pdt_dis.week_end_date >= terr.valid_from::DATE
    AND (terr.valid_to IS NULL OR pdt_dis.week_end_date < terr.valid_to::DATE)

LEFT JOIN prod
    ON pdt_dis.product_id = prod.product_id



