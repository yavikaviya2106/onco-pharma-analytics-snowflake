
WITH source AS (
    SELECT * FROM {{ ref('raw_iqvia_xponent_data') }}
)

SELECT

    NULLIF(TRIM(xponent_record_id), '')                 AS xponent_record_id,

    NULLIF(TRIM(prescriber_id), '')                     AS iqvia_hcp_id,
    {{ normalize_npi('npi') }}                          AS hcp_npi,
    NULLIF(TRIM(prescriber_specialty), '')              AS prescriber_specialty,

    {{ normalize_ndc('ndc') }}                          AS ndc_code,
    NULLIF(TRIM(product_name), '')                      AS product_name,
    NULLIF(TRIM(brand_name), '')                        AS brand_name,
    NULLIF(TRIM(generic_name), '')                      AS generic_name,

    week_end_date                     AS week_end_date,

    TRY_TO_DECIMAL(trx::VARCHAR, 10,0)                       AS trx,
    TRY_TO_DECIMAL(nrx::VARCHAR, 10,0)                       AS nrx,
    TRY_TO_DECIMAL(nbrx::VARCHAR, 10,0)                      AS nbrx,
    TRY_TO_DECIMAL(refill_rx::VARCHAR, 10,0)                 AS refill_rx,

    TRY_TO_DECIMAL(trx_units::VARCHAR, 12,0)                 AS trx_units,
    TRY_TO_DECIMAL(nrx_units::VARCHAR, 12,0)                 AS nrx_units,
    TRY_TO_DECIMAL(nbrx_units::VARCHAR, 12,0)                AS nbrx_units,

    TRY_TO_DECIMAL(market_trx::VARCHAR, 10,0)                AS market_trx,
    TRY_TO_DECIMAL(market_nrx::VARCHAR, 10,0)                AS market_nrx,

    TRY_TO_TIMESTAMP_NTZ(source_updated_at::VARCHAR)        AS source_updated_at,
    UPPER(NULLIF(TRIM(source_system), ''))              AS source_system

FROM source
