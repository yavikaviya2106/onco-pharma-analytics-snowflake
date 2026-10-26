{% macro p1_assert_equal(left_expr, right_expr) %}
    ({{ left_expr }}) = ({{ right_expr }})
{% endmacro %}
