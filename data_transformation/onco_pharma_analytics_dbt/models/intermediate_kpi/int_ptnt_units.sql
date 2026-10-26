WITH ptnt AS (
    SELECT
        source_transaction_id,
        patient_id,
        hub_case_id,
        sp_case_id,
        dim_hcp_sk,
        hcp_npi,
        dim_prod_sk,
        product_id,
        quantity_dispensed,
        days_supply,
        shipment_date,
        delivery_date,
        unit_source
    FROM {{ ref('idl_ptnt_txn_units') }}
),

time_bucket AS (
    SELECT
        NULL AS product_id,
        bucket_type,
        bucket_name,
        bucket_start_date,
        bucket_end_date
    FROM {{ ref('dim_time_bucket') }}

    UNION ALL

    SELECT
        product_id,
        bucket_type,
        bucket_name,
        bucket_start_date,
        bucket_end_date
    FROM {{ ref('dim_pdt_time_bucket') }}
)

SELECT
    ptnt.patient_id AS patient_id,
    ptnt.hub_case_id AS hub_case_id,
    ptnt.sp_case_id AS sp_case_id,

    ptnt.dim_hcp_sk AS dim_hcp_sk,
    ptnt.hcp_npi AS hcp_npi,

    ptnt.dim_prod_sk AS dim_prod_sk,
    ptnt.product_id AS product_id,

    t.bucket_type AS bucket_type,
    t.bucket_name AS bucket_name,
    t.bucket_start_date                                      AS bucket_start_date,
    t.bucket_end_date                                        AS bucket_end_date,

    SUM(CASE
            WHEN ptnt.unit_source = 'PAP'
            THEN ptnt.quantity_dispensed
            ELSE 0
        END) AS pap_units,

    SUM(CASE
            WHEN ptnt.unit_source = 'SP'
            THEN ptnt.quantity_dispensed
            ELSE 0
        END) AS sp_units

FROM  ptnt

INNER JOIN time_bucket t
    ON ptnt.shipment_date
        BETWEEN t.bucket_start_date AND t.bucket_end_date
    AND (t.product_id IS NULL
        OR ptnt.product_id = t.product_id)

GROUP BY
    ptnt.patient_id,
    ptnt.hub_case_id,
    ptnt.sp_case_id,
    ptnt.dim_hcp_sk,
    ptnt.hcp_npi,
    ptnt.dim_prod_sk,
    ptnt.product_id,
    t.bucket_type,
    t.bucket_name,
    t.bucket_start_date,
    t.bucket_end_date