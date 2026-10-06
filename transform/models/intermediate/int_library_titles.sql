-- What the library apps manage: one row per movie (imdb) or series (tvdb), with its size on disk.
with movies as (
    select
        'movie' as media_type,
        tmdb_id,
        movie_id as library_id,
        title,
        release_year,
        added_at,
        has_file as is_downloaded,
        size_on_disk_bytes
    from {{ ref('stg_imdb__movies') }}
),

series as (
    select
        'series' as media_type,
        tmdb_id,
        series_id as library_id,
        title,
        release_year,
        added_at,
        episode_file_count > 0 as is_downloaded,
        size_on_disk_bytes
    from {{ ref('stg_tvdb__series') }}
)

select {{ title_key('media_type', 'tmdb_id') }} as title_key, *
from (select * from movies union all select * from series)
