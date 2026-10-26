WITH indication AS (
    SELECT * FROM {{ ref('stg_indication_details') }}
),

generic AS (
    SELECT 
        dim_generic_sk, 
        generic_id,
        generic_name
    FROM {{ ref('dim_generic_details') }}
),

brand AS (
    SELECT 
        dim_brand_sk, 
        brand_id 
    FROM {{ ref('dim_brand_details') }}
),

disease AS (
    SELECT 
        dim_disease_sk, 
        disease_id,
        disease_name,
        therapeutic_area
    FROM {{ ref('dim_disease_details') }}
)

SELECT

    {{ dbt_utils.generate_surrogate_key(['indication.indication_id']) }} AS dim_indication_sk,
    indication.indication_id                                        AS indication_id,
    
    generic.dim_generic_sk                                          AS dim_generic_sk,
    indication.generic_id                                           AS generic_id,
    COALESCE(indication.generic_name,generic.generic_name)          AS generic_name,
    
    brand.dim_brand_sk                                              AS dim_brand_sk,
    indication.brand_id                                             AS brand_id,
    
    disease.dim_disease_sk                                          AS dim_disease_sk,
    indication.disease_id,
    COALESCE(indication.disease_name,disease.disease_name)          AS disease_name,
    COALESCE(indication.therapeutic_area,disease.therapeutic_area)  AS therapeutic_area,
   
    indication.type_of_therapy                                      AS type_of_therapy,
    indication.line_of_therapy                                      AS line_of_therapy,
    indication.route_of_administration                              AS route_of_administration,
    indication.standard_dose                                        AS standard_dose,
    indication.dose_unit                                            AS dose_unit,
    indication.dosage_form                                          AS dosage_form,
    indication.units_per_day                                        AS units_per_day,
    indication.frequency                                            AS frequency,
    indication.treatment_duration                                   AS treatment_duration,
    indication.schedule_type                                        AS schedule_type,
    indication.food_requirement                                     AS food_requirement,
    indication.guideline_reference                                  AS guideline_reference,

    indication.source_updated_at                                    AS source_updated_at
    
FROM indication

LEFT JOIN generic 
    ON indication.generic_id = generic.generic_id

LEFT JOIN brand 
    ON indication.brand_id = brand.brand_id

LEFT JOIN disease 
    ON indication.disease_id = disease.disease_id
