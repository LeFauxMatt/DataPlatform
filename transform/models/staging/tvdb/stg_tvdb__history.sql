select
    id as event_id,
    series_id,
    episode_id,
    event_type,
    cast(date as timestamptz) as event_at,
    source_title,
    download_id,
    quality ->> '$.quality.name' as quality_name,
    cast(episode ->> '$.seasonNumber' as integer) as season_number,
    cast(episode ->> '$.episodeNumber' as integer) as episode_number
from {{ source('tvdb', 'history') }}
