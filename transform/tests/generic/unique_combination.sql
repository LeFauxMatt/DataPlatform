{#- A custom generic test: no two rows share the same values across `columns`.
    (dbt_utils has one; this project keeps to dbt Core with no packages.) -#}
{% test unique_combination(model, columns) %}
select {{ columns | join(', ') }}, count(*) as rows_sharing
from {{ model }}
group by {{ columns | join(', ') }}
having count(*) > 1
{% endtest %}
