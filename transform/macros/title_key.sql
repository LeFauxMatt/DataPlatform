{#- One title's key across every app: its media type and TMDB id, e.g. movie-603 or series-1399.
    TMDB is the id that both library apps, trakt and Jellyfin all carry. -#}
{% macro title_key(media_type, tmdb_id) -%}
    case when {{ tmdb_id }} is not null then {{ media_type }} || '-' || cast({{ tmdb_id }} as varchar) end
{%- endmacro %}
