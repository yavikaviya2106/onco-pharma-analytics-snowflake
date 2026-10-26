{% for model, key in [('dim_hcp_master','onekey_hcp_id'),('dim_hco_master','onekey_hco_id'),
    ('dim_address_master','address_id'),('dim_field_force_master','rep_id'),('dim_terr_algn','territory_id')] %}

    SELECT 
        '{{ model }}' AS model_name, 
        {{ key }}::VARCHAR AS natural_key 
    FROM {{ ref(model) }}
    QUALIFY valid_from < LAG(COALESCE(valid_to, '9999-12-31'::TIMESTAMP)) OVER (PARTITION BY {{ key }} ORDER BY valid_from)

{% if not loop.last %} 

    UNION ALL 
    
{% endif %}

{% endfor %}
