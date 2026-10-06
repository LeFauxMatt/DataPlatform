select
    id as movie_id,
    nullif(tmdb_id, 0) as tmdb_id,
    imdb_id,
    title,
    year as release_year,
    status as movie_status,
    monitored as is_monitored,
    has_file,
    cast(added as timestamptz) as added_at,
    size_on_disk as size_on_disk_bytes
from {{ source('imdb', 'movie') }}
