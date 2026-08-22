{# Honour the literal +database config so models land in SLV and GLD rather
   than all defaulting to the target database. #}
{% macro generate_database_name(custom_database_name, node) -%}
    {%- if custom_database_name is none -%}
        {{ target.database }}
    {%- else -%}
        {{ custom_database_name | trim }}
    {%- endif -%}
{%- endmacro %}
