WITH source AS (
    SELECT
        source_transaction_id,
        patient_id,
        hub_case_id,
        sp_case_id,
        dim_hcp_sk,
        hcp_npi,
        dim_prod_sk,
        product_id,
        transaction_date,
        shipment_date,
        delivery_date,
        unit_source,
        days_supply,
        units_dispensed
    FROM {{ ref('idl_ptnt_txn_units') }}
    WHERE unit_source IN ('SP', 'PAP')
        AND shipment_date IS NOT NULL
        AND days_supply > 0
        AND units_dispensed > 0
),

sequenced AS (
    SELECT
        *,
        ROW_NUMBER() 
            OVER (PARTITION BY patient_id, dim_prod_sk
            ORDER BY shipment_date, source_transaction_id, unit_source) AS fill_number,
        
        ROW_NUMBER() 
            OVER (PARTITION BY patient_id, dim_prod_sk, unit_source
            ORDER BY shipment_date, source_transaction_id) AS channel_fill_number,
        
        LAG(shipment_date) 
            OVER (PARTITION BY patient_id, dim_prod_sk
            ORDER BY shipment_date, source_transaction_id, unit_source) AS previous_fill_date,
        
        LEAD(shipment_date) 
            OVER (PARTITION BY patient_id, dim_prod_sk
            ORDER BY shipment_date, source_transaction_id, unit_source) AS next_fill_date,
        
        MIN(shipment_date) 
            OVER (PARTITION BY patient_id, dim_prod_sk) AS first_fill_date,
        
        MAX(shipment_date) 
            OVER (PARTITION BY patient_id, dim_prod_sk) AS last_fill_date,
        
        DATEADD(DAY, days_supply - 1, shipment_date) AS coverage_end_date
    FROM source
),

coverage AS (
    SELECT
        *,
        MAX(coverage_end_date) OVER (
            PARTITION BY patient_id, dim_prod_sk
            ORDER BY shipment_date, source_transaction_id, unit_source
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        ) AS previous_coverage_end_date
    FROM sequenced
),

derived AS (
    SELECT
        *,
        CASE
            WHEN previous_fill_date IS NOT NULL
            THEN DATEDIFF(DAY, previous_fill_date, shipment_date)
        END AS days_between_fills,
        CASE
            WHEN previous_coverage_end_date IS NOT NULL
            THEN GREATEST(DATEDIFF(DAY, DATEADD(DAY, 1, previous_coverage_end_date), shipment_date), 0)
        END AS therapy_gap_days
    FROM coverage
)

SELECT
    source_transaction_id AS source_transaction_id,
    patient_id AS patient_id,
    hub_case_id AS hub_case_id,
    sp_case_id AS sp_case_id,
    dim_hcp_sk AS dim_hcp_sk,
    hcp_npi AS hcp_npi,
    dim_prod_sk AS dim_prod_sk,
    product_id AS product_id,
    unit_source AS unit_source,
    transaction_date AS transaction_date,
    shipment_date AS fill_date,
    delivery_date AS delivery_date,
    fill_number AS fill_number,
    channel_fill_number AS channel_fill_number,
    CASE WHEN fill_number = 1 THEN 'INITIAL' ELSE 'REFILL' END AS fill_type,
    (fill_number = 1) AS initial_fill_flag,
    (fill_number > 1) AS refill_flag,
    (channel_fill_number = 1) AS channel_initial_fill_flag,
    (channel_fill_number > 1) AS channel_refill_flag,
    first_fill_date AS initial_fill_date,
    last_fill_date AS last_fill_date,
    previous_fill_date AS previous_fill_date,
    next_fill_date AS next_fill_date,
    days_between_fills AS days_between_fills,
    days_supply AS days_supply,
    units_dispensed AS quantity_dispensed,
    coverage_end_date AS coverage_end_date,
    previous_coverage_end_date AS previous_coverage_end_date,
    therapy_gap_days AS therapy_gap_days,
    (COALESCE(therapy_gap_days, 0) > 0) AS therapy_gap_flag,
    (COALESCE(therapy_gap_days, 0) >= 30) AS gap_30_flag,
    (COALESCE(therapy_gap_days, 0) >= 60) AS gap_60_flag,
    (COALESCE(therapy_gap_days, 0) >= 90) AS gap_90_flag
FROM derived
