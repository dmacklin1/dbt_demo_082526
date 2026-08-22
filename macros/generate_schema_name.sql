{# Use the literal schema from dbt_project.yml instead of prefixing it with the
   target schema. Required for a medallion layout where schema names are fixed
   (FACTS, DIMS, OUTPUT) rather than developer-scoped. #}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
