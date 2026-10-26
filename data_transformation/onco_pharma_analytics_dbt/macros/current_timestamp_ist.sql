{% macro current_timestamp_ist() %}

    CONVERT_TIMEZONE(
        'Asia/Kolkata',
        CURRENT_TIMESTAMP()
    )::TIMESTAMP_NTZ

{% endmacro %}