WITH source AS (
    SELECT * FROM {{ ref('raw_product_indication_details') }}
)
   
    
SELECT
        
    NULLIF(TRIM(indication_id), '')                         AS indication_id,
    NULLIF(TRIM(brand_id), '')                              AS brand_id,
    NULLIF(TRIM(disease_id), '')                            AS disease_id,
    NULLIF(TRIM(generic_id), '')                            AS generic_id,
    
    NULLIF(TRIM(generic_name), '')                          AS generic_name,
    NULLIF(TRIM(disease_name), '')                          AS disease_name,
    NULLIF(TRIM(therapeutic_area), '')                      AS therapeutic_area,
    
    NULLIF(TRIM(type_of_therapy), '')                       AS type_of_therapy,
    NULLIF(TRIM(line_of_therapy), '')                       AS line_of_therapy,
    UPPER(NULLIF(TRIM(route_of_administration), ''))        AS route_of_administration,
    TRY_TO_DECIMAL(standard_dose::VARCHAR, 10,2)                  AS standard_dose,
    NULLIF(TRIM(dose_unit), '')                             AS dose_unit,
    NULLIF(TRIM(dosage_form), '')                           AS dosage_form,
    TRY_TO_DECIMAL(units_per_day::VARCHAR, 10,2)                  AS units_per_day,
    NULLIF(TRIM(frequency), '')                             AS frequency,
        
    NULLIF(TRIM(treatment_duration), '')                    AS treatment_duration,
    UPPER(NULLIF(TRIM(schedule_type), ''))                  AS schedule_type,
    TRY_TO_DECIMAL(on_days::VARCHAR, 7,2)                        AS on_days,
    TRY_TO_DECIMAL(off_days::VARCHAR, 7,2)                       AS off_days,
    NULLIF(TRIM(food_requirement), '')                      AS food_requirement,
    NULLIF(TRIM(guideline_reference), '')                   AS guideline_reference,
        
    TRY_TO_TIMESTAMP_NTZ(source_updated_at::VARCHAR)            AS source_updated_at,
    UPPER(NULLIF(TRIM(source_system), ''))                  AS source_system

FROM source
