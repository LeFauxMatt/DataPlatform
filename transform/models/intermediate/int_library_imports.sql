-- Every time a file for a title landed in the library, from either library app's history.
with imdb as (
    select
        {{ title_key("'movie'", 'm.tmdb_id') }} as title_key,
        h.event_at as imported_at,
        h.quality_name
    from {{ ref('stg_imdb__history') }} as h
    inner join {{ ref('stg_imdb__movies') }} as m on h.movie_id = m.movie_id
    where h.event_type in ('downloadFolderImported', 'movieFolderImported')
),

tvdb as (
    select
        {{ title_key("'series'", 's.tmdb_id') }} as title_key,
        h.event_at as imported_at,
        h.quality_name
    from {{ ref('stg_tvdb__history') }} as h
    inner join {{ ref('stg_tvdb__series') }} as s on h.series_id = s.series_id
    where h.event_type in ('downloadFolderImported', 'seriesFolderImported')
)

select * from imdb where title_key is not null
union all
select * from tvdb where title_key is not null
