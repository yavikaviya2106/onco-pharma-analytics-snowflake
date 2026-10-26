WITH disease AS (
    SELECT * FROM {{ ref('stg_disease_details') }}
)


SELECT

    {{ dbt_utils.generate_surrogate_key(['disease_id']) }} as dim_disease_sk,
    disease_id,
    disease_name,
    therapeutic_area,
    
    cancer_type,
    biomarker_required,
    biomarker_name,
    diagnosis_specialties,
    prescribing_specialty,

    source_updated_at

FROM disease

