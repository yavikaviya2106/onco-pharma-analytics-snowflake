WITH generic AS (
    SELECT * FROM {{ ref('stg_generic_details') }}
)


SELECT

    {{ dbt_utils.generate_surrogate_key(['generic_id']) }} AS dim_generic_sk,
    generic_id,
    generic_name,
    
    therapeutic_area,
    drug_class,
    mechanism_action,
    targets,
    
    source_updated_at

FROM generic
