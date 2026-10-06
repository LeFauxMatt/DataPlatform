select
    id as series_id,
    nullif(tmdb_id, 0) as tmdb_id,
    nullif(tvdb_id, 0) as tvdb_id,
    imdb_id,
    title,
    year as release_year,
    status as series_status,
    network,
    monitored as is_monitored,
    cast(added as timestamptz) as added_at,
    cast(statistics ->> '$.episodeCount' as integer) as episode_count,
    cast(statistics ->> '$.episodeFileCount' as integer) as episode_file_count,
    cast(statistics ->> '$.sizeOnDisk' as bigint) as size_on_disk_bytes
from {{ source('tvdb', 'series') }}
