WITH hub_units AS (
    SELECT
        patient_id,
        hub_case_id,
        NULL AS sp_case_id,
        dim_hcp_sk,
        hcp_npi,
        dim_prod_sk,
        product_id,
        hub_pap_transaction_id AS source_transaction_id,
        transaction_date,
        transaction_type,
        transaction_status,
        fill_number,
        quantity_dispensed,
        days_supply,
        shipment_date,
        delivery_date,
        'PAP' AS unit_source
    FROM {{ ref('fct_hub_transactions') }}
    WHERE UPPER(transaction_status) = 'COMPLETED'
      AND quantity_dispensed > 0
      AND shipment_date IS NOT NULL
),

sp_units AS (
    SELECT
        patient_id,
        hub_case_id,
        sp_case_id,
        dim_hcp_sk,
        hcp_npi,
        dim_prod_sk,
        product_id,
        sp_transaction_id AS source_transaction_id,
        transaction_date,
        transaction_type,
        transaction_status,
        fill_number,
        quantity_dispensed,
        days_supply,
        shipment_date,
        delivery_date,
        'SP' AS unit_source
    FROM {{ ref('fct_sp_transactions') }}

    WHERE UPPER(TRIM(transaction_status)) IN ('CLOSED - DELIVERED','IN PROGRESS - SHIPPED')
      AND UPPER(TRIM(transaction_type)) IN ('INITIAL FILL','REFILL')
      AND quantity_dispensed > 0
      AND days_supply > 0
      AND shipment_date IS NOT NULL
),

patient_units AS (
    SELECT * FROM hub_units
    UNION ALL
    SELECT * FROM sp_units
)

SELECT
    source_transaction_id                               AS source_transaction_id,
    patient_id                                          AS patient_id,
    hub_case_id                                         AS hub_case_id,
    sp_case_id                                          AS sp_case_id,

    dim_hcp_sk                                          AS dim_hcp_sk,
    hcp_npi                                             AS hcp_npi,

    dim_prod_sk                                         AS dim_prod_sk,
    product_id                                          AS product_id,

    transaction_type                                    AS transaction_type,
    transaction_status                                  AS transaction_status,

    fill_number                                         AS source_fill_number,
    quantity_dispensed                                  AS quantity_dispensed,
    quantity_dispensed                                  AS units_dispensed,
    days_supply                                         AS days_supply,

    transaction_date                                    AS transaction_date,
    shipment_date                                       AS shipment_date,
    delivery_date                                       AS delivery_date,
    unit_source                                         AS unit_source,

    CASE
        WHEN unit_source = 'PAP' THEN quantity_dispensed
        ELSE 0
    END                                                 AS pap_units,
    CASE
        WHEN unit_source = 'SP' THEN quantity_dispensed
        ELSE 0
    END                                                 AS sp_units

FROM patient_units