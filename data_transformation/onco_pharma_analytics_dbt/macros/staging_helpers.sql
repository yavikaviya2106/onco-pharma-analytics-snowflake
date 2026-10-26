{% macro normalize_flag(column_name) %}
    CASE
        WHEN UPPER(TRIM({{ column_name }})) IN ('Y', 'YES', '1', 'TRUE', 'T') THEN TRUE
        WHEN UPPER(TRIM({{ column_name }})) IN ('N', 'NO', '0', 'FALSE', 'F') THEN FALSE
        ELSE NULL
    END
{% endmacro %}

{% macro normalize_npi(column_name) %}
    NULLIF(TRIM({{ column_name }}::STRING), '')
{% endmacro %}


{% macro normalize_ndc(column_name) %}
    CASE
        WHEN {{ column_name }} IS NULL OR TRIM({{ column_name }}) = '' THEN NULL
        WHEN CONTAINS({{ column_name }}, '-') THEN
            LPAD(SPLIT_PART({{ column_name }}, '-', 1), 5, '0') ||
            LPAD(SPLIT_PART({{ column_name }}, '-', 2), 4, '0') ||
            LPAD(SPLIT_PART({{ column_name }}, '-', 3), 2, '0')
        ELSE
            LPAD(TRIM({{ column_name }}), 11, '0')
    END
{%- endmacro %}



