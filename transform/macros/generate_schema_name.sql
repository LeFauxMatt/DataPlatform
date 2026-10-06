{#- Use a model's +schema as-is (staging, marts) instead of dbt's default <target schema>_<custom schema>,
    so the DuckDB file reads as raw_* → staging → intermediate → marts. -#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {{ custom_schema_name | trim if custom_schema_name else target.schema }}
{%- endmacro %}
