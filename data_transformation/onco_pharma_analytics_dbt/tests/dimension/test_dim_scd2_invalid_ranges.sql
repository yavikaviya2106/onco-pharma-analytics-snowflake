{% for model in ['dim_hcp_master','dim_hco_master','dim_address_master','dim_field_force_master','dim_terr_algn'] %}

    SELECT 
        '{{ model }}' AS model_name, 
        COUNT(*) AS violations 
    FROM {{ ref(model) }} 
    WHERE valid_to IS NOT NULL 
        AND valid_to <= valid_from 
    GROUP BY 1
    HAVING COUNT(*) > 0

{% if not loop.last %} 

UNION ALL {% endif %}

{% endfor %}
