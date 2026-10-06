select
    id as event_id,
    movie_id,
    event_type,
    cast(date as timestamptz) as event_at,
    source_title,
    download_id,
    quality ->> '$.quality.name' as quality_name
from {{ source('imdb', 'history') }}
