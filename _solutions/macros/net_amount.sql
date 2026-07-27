#{% macro net_amount(price_col, discount_col) %}
    {{ price_col }} * (1 - {{ discount_col }})
{% endmacro %}
